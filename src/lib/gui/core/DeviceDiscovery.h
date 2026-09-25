/*
 * Deskflow-cn -- mouse and keyboard sharing utility
 * SPDX-License-Identifier: GPL-2.0-only WITH LicenseRef-OpenSSL-Exception
 */

#pragma once

#include <QObject>

class QTimer;
class QUdpSocket;

namespace deskflow::gui {

/**
 * Lightweight LAN discovery used by Deskflow-cn.
 *
 * Servers periodically advertise their name and core port over IPv4 broadcast.
 * Clients listen for those announcements and can update a previously paired
 * server address automatically when DHCP changes its IP.
 */
class DeviceDiscovery : public QObject
{
  Q_OBJECT

public:
  enum class Mode
  {
    Disabled,
    Client,
    Server
  };
  Q_ENUM(Mode)

  explicit DeviceDiscovery(QObject *parent = nullptr);

  void setMode(Mode mode);
  void setServerInfo(const QString &computerName, quint16 corePort);
  Mode mode() const
  {
    return m_mode;
  }

Q_SIGNALS:
  void serverDiscovered(const QString &address, const QString &computerName, quint16 corePort);

private:
  void startClient();
  void startServer();
  void stop();
  void broadcastServer();
  void readPendingDatagrams();

  inline static constexpr quint16 kDiscoveryPort = 24801;
  inline static constexpr int kBroadcastIntervalMs = 1500;

  QUdpSocket *m_socket = nullptr;
  QTimer *m_broadcastTimer = nullptr;
  Mode m_mode = Mode::Disabled;
  QString m_serverName;
  quint16 m_corePort = 24800;
};

} // namespace deskflow::gui
