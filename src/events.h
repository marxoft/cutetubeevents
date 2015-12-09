/*
 * Copyright (C) 2015 Stuart Howarth <showarth@marxoft.co.uk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef EVENTS_H
#define EVENTS_H

#include <QObject>
#include <QList>
#include <QDateTime>
#include <QVariantMap>

namespace QDailymotion {
    class ResourcesRequest;
}

namespace QVimeo {
    class ResourcesRequest;
}

namespace QYouTube {
    class ResourcesRequest;
}

class QNetworkAccessManager;
class QNetworkReply;

class Events : public QObject
{
    Q_OBJECT
    
public:
    explicit Events(QObject *parent = 0);
    
    void getEvents();

private:
    void fetchDailymotionFeed();
    void fetchVimeoFeed();
    void fetchYouTubeFeed();
    
    void initDailymotionRequest();
    void initVimeoRequest();
    void initYouTubeRequest();
    
    void initNetworkAccessManager();
    
    void nextEvent();
    
    void nextFeed();
    
    void readAction();
    
    void readFeeds();
    void writeFeeds();
    
private Q_SLOTS:
    void cacheImage(QNetworkReply *reply);
    
    void parseDailymotionFeed();
    void parseVimeoFeed();
    void parseYouTubeFeed();
    
Q_SIGNALS:
    void finished();
    
private:
    QDailymotion::ResourcesRequest *m_dailymotionRequest;
    QVimeo::ResourcesRequest *m_vimeoRequest;
    QYouTube::ResourcesRequest *m_youtubeRequest;
    QNetworkAccessManager *m_nam;
    
    struct Feed {
        QString service;
        QString feedType;
        QString query;
        int maxResults;
        QDateTime lastUpdated;
    };
    
    int m_index;
    QList<Feed> m_feeds;
    QList<QVariantMap> m_events;
    QString m_imageFileName;

    QString m_action;
    bool m_useCustomAction;
};
    
#endif // EVENTS_H
