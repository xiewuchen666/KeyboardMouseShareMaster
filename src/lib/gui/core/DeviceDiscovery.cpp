/*
 * Deskflow-cn -- mouse and keyboard sharing utility
 * SPDX-License-Identifier: GPL-2.0-only WITH LicenseRef-OpenSSL-Exception
 */

#include "DeviceDiscovery.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkDatagram>
#include <QNetworkInterface>
#include <QSet>
#include <QTimer>
#include <QUdpSocket>

namespace deskflow::gui {

namespace {
const auto kDiscoveryMagic = QStringLiteral("deskflow-cn-discovery-v1");
}

DeviceDiscovery::DeviceDiscovery(QObject *parent)
    : QObject(parent),
      m_socket(new QUdpSocket(this)),
      m_broadcastTimer(new QTimer(this))
{
  m_broadcastTimer->setInterval(kBroadcastIntervalMs);
  connect(m_broadcastTimer, &QTimer::timeout, this, &DeviceDiscovery::broadcastServer);
  connect(m_socket, &QUdpSocket::readyRead, this, &DeviceDiscovery::readPendingDatagrams);
}

void DeviceDiscovery::setServerInfo(const QString &computerName, quint16 corePort)
{
  m_serverName = computerName;
  m_corePort = corePort;
}

void DeviceDiscovery::setMode(Mode mode)
{
  if (m_mode == mode)
    return;

  stop();
  m_mode = mode;

  if (m_mode == Mode::Client)
    startClient();
  else if (m_mode == Mode::Server)
    startServer();
}

void DeviceDiscovery::startClient()
{
  const auto flags = QUdpSocket::ShareAddress | QUdpSocket::ReuseAddressHint;
  if (!m_socket->bind(QHostAddress::AnyIPv4, kDiscoveryPort, flags)) {
    qWarning().noquote() << "device discovery failed to bind UDP port" << kDiscoveryPort << ":" << m_socket->errorString();
    return;
  }

  qInfo() << "device discovery listening for Deskflow-cn servers on UDP port" << kDiscoveryPort;
}

void DeviceDiscovery::startServer()
{
  broadcastServer();
  m_broadcastTimer->start();
  qInfo() << "device discovery advertising Deskflow-cn server on UDP port" << kDiscoveryPort;
}

void DeviceDiscovery::stop()
{
  m_broadcastTimer->stop();
  m_socket->close();
}

void DeviceDiscovery::broadcastServer()
{
  if (m_mode != Mode::Server || m_serverName.isEmpty())
    return;

  const QJsonObject payloadObject{
      {QStringLiteral("magic"), kDiscoveryMagic},
      {QStringLiteral("name"), m_serverName},
      {QStringLiteral("port"), static_cast<int>(m_corePort)}
  };
  const auto payload = QJsonDocument(payloadObject).toJson(QJsonDocument::Compact);

  QSet<QHostAddress> broadcastAddresses;
  const auto interfaces = QNetworkInterface::allInterfaces();
  for (const auto &interface : interfaces) {
    if (!(interface.flags() & QNetworkInterface::IsUp) || !(interface.flags() & QNetworkInterface::IsRunning) ||
        (interface.flags() & QNetworkInterface::IsLoopBack)) {
      continue;
    }

    for (const auto &entry : interface.addressEntries()) {
      if (entry.ip().protocol() != QAbstractSocket::IPv4Protocol)
        continue;

      if (!entry.broadcast().isNull())
        broadcastAddresses.insert(entry.broadcast());
    }
  }

  // Fallback for adapters where Qt does not expose the subnet broadcast address.
  if (broadcastAddresses.isEmpty())
    broadcastAddresses.insert(QHostAddress::Broadcast);

  for (const auto &address : broadcastAddresses)
    m_socket->writeDatagram(payload, address, kDiscoveryPort);
}

void DeviceDiscovery::readPendingDatagrams()
{
  if (m_mode != Mode::Client)
    return;

  while (m_socket->hasPendingDatagrams()) {
    const auto datagram = m_socket->receiveDatagram();
    const auto document = QJsonDocument::fromJson(datagram.data());
    if (!document.isObject())
      continue;

    const auto object = document.object();
    if (object.value(QStringLiteral("magic")).toString() != kDiscoveryMagic)
      continue;

    const auto computerName = object.value(QStringLiteral("name")).toString().trimmed();
    const auto corePortValue = object.value(QStringLiteral("port")).toInt();
    if (computerName.isEmpty() || corePortValue <= 0 || corePortValue > 65535)
      continue;

    const auto senderAddress = datagram.senderAddress().toString();
    if (senderAddress.isEmpty())
      continue;

    Q_EMIT serverDiscovered(senderAddress, computerName, static_cast<quint16>(corePortValue));
  }
}

} // namespace deskflow::gui
