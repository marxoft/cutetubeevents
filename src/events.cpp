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

#include "events.h"
#include <qdailymotion/resourcesrequest.h>
#include <qvimeo/resourcesrequest.h>
#include <qyoutube/resourcesrequest.h>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDir>
#include <QImage>
#include <QFile>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QRegExp>

static const QString ACTION_FILE("/home/user/.local/share/data/cutetubeevents/action");
static const QString FEEDS_FILE("/home/user/.local/share/data/cutetubeevents/feeds");

static const QString IMAGE_CACHE_PATH("/home/user/.local/share/data/cutetubeevents/cache/");

static const QString DEFAULT_ICON("cutetubeevents");

static const QString DBUS_SERVICE("org.hildon.eventfeed");
static const QString DBUS_PATH("/org/hildon/eventfeed");
static const QString DBUS_INTERFACE("org.hildon.eventfeed");
static const QString DBUS_METHOD("addItem");

static const QStringList DAILYMOTION_VIDEO_FIELDS = QStringList() << "id" << "created_time" << "description"
                                                                  << "owner.screenname" << "thumbnail_120_url"
                                                                  << "title" << "url";

static const QString VIMEO_CLIENT_ID("0bf284bf5a0e46630f5097a590a76ef976a94322");
static const QString VIMEO_CLIENT_SECRET("7nnZ1OPS13hjKAVhzuXx/4AIdKxmgDNasHkj5QraWWkrNsd6mxYWZG73AKaFUdLzoNWhGA75jSffs\
+JyAFfi0MiFi1OXnzHsxaL0HCIFpxk0GpZlXcScWmJTHvGGtVv1");
static const QString VIMEO_CLIENT_TOKEN("fb5c66ebe6938e858921963f850355a0");

static const QString YOUTUBE_API_KEY("AIzaSyDhIlkLzHJKDCNr6thsjlQpZrkY3lO_Uu4");

static qlonglong addItemToEventFeed(const QVariantMap &item) {
    QDBusMessage message = QDBusMessage::createMethodCall(DBUS_SERVICE, DBUS_PATH, DBUS_INTERFACE, DBUS_METHOD);
    message.setArguments(QVariantList() << item);
    const QVariantList args = QDBusConnection::sessionBus().call(message).arguments();    
    return args.isEmpty() ? -1 : args.first().toLongLong();
}

Events::Events(QObject *parent) :
    QObject(parent),
    m_dailymotionRequest(0),
    m_vimeoRequest(0),
    m_youtubeRequest(0),
    m_nam(0),
    m_index(-1),
    m_useCustomAction(false)
{
}

void Events::getEvents() {
    if (!m_feeds.isEmpty()) {
        return;
    }
    
    m_index = -1;
    readFeeds();
    readAction();
    
    if (m_feeds.isEmpty()) {
        emit finished();
    }
    else {
        nextFeed();
    }
}

void Events::nextEvent() {
    if (m_events.isEmpty()) {
        emit finished();
        return;
    }
    
    const QStringList imageList = m_events.first().value("imageList").toStringList();
    
    if (!imageList.isEmpty()) {
        m_imageFileName = IMAGE_CACHE_PATH + imageList.first().toUtf8().toBase64() + ".jpg";
        
        if (!QFile::exists(m_imageFileName)) {
            initNetworkAccessManager();
            m_nam->get(QNetworkRequest(imageList.first()));
            return;
        }
    }
    
    addItemToEventFeed(m_events.takeFirst());
    nextEvent();
}       

void Events::nextFeed() {
    m_index++;
    
    if (m_index == m_feeds.size()) {
        writeFeeds();
        m_feeds.clear();
        m_index = -1;
        nextEvent();
        return;
    }
    
    const QString service = m_feeds.at(m_index).service;
    
    if (service == "dailymotion") {
        fetchDailymotionFeed();
    }
    else if (service == "vimeo") {
        fetchVimeoFeed();
    }
    else {
        fetchYouTubeFeed();
    }
}

void Events::initDailymotionRequest() {
    if (m_dailymotionRequest) {
        return;
    }
    
    m_dailymotionRequest = new QDailymotion::ResourcesRequest(this);
    connect(m_dailymotionRequest, SIGNAL(finished()), this, SLOT(parseDailymotionFeed()));
}

void Events::initVimeoRequest() {
    if (m_vimeoRequest) {
        return;
    }
    
    m_vimeoRequest = new QVimeo::ResourcesRequest(this);
    m_vimeoRequest->setClientId(VIMEO_CLIENT_ID);
    m_vimeoRequest->setClientSecret(VIMEO_CLIENT_SECRET);
    m_vimeoRequest->setAccessToken(VIMEO_CLIENT_TOKEN);
    connect(m_vimeoRequest, SIGNAL(finished()), this, SLOT(parseVimeoFeed()));
}

void Events::initYouTubeRequest() {
    if (m_youtubeRequest) {
        return;
    }
    
    m_youtubeRequest = new QYouTube::ResourcesRequest(this);
    m_youtubeRequest->setApiKey(YOUTUBE_API_KEY);
    connect(m_youtubeRequest, SIGNAL(finished()), this, SLOT(parseYouTubeFeed()));
}

void Events::initNetworkAccessManager() {
    if (m_nam) {
        return;
    }
    
    m_nam = new QNetworkAccessManager(this);
    connect(m_nam, SIGNAL(finished(QNetworkReply*)), this, SLOT(cacheImage(QNetworkReply*)));
}

void Events::fetchDailymotionFeed() {
    initDailymotionRequest();
    QVariantMap filters;
    filters["limit"] = m_feeds.at(m_index).maxResults;
    filters["family_filter"] = false;
    
    if (m_feeds.at(m_index).feedType == "channel") {
        m_dailymotionRequest->list(QString("/user/%1/videos").arg(m_feeds.at(m_index).query),
                                   filters, DAILYMOTION_VIDEO_FIELDS);
    }
    else {
        filters["search"] = m_feeds.at(m_index).query;
        filters["sort"] = "recent";
        m_dailymotionRequest->list("/videos", filters, DAILYMOTION_VIDEO_FIELDS);
    }
}

void Events::fetchVimeoFeed() {
    initVimeoRequest();
    QVariantMap filters;
    filters["per_page"] = m_feeds.at(m_index).maxResults;
    
    if (m_feeds.at(m_index).feedType == "channel") {
        m_vimeoRequest->list(QString("/users/%1/videos").arg(m_feeds.at(m_index).query), filters);
    }
    else {
        filters["query"] = m_feeds.at(m_index).query;
        filters["sort"] = "date";
        m_vimeoRequest->list("/videos", filters);
    }
}

void Events::fetchYouTubeFeed() {
    initYouTubeRequest();
    QVariantMap params;
    params["maxResults"] = m_feeds.at(m_index).maxResults;
    params["safeSearch"] = "none";
    params["type"] = "video";
    params["order"] = "date";
    
    if (m_feeds.at(m_index).feedType == "channel") {
        params["channelId"] = m_feeds.at(m_index).query;
    }
    else {
        params["q"] = m_feeds.at(m_index).query;
    }
    
    m_youtubeRequest->list("/search", QStringList("snippet"), QVariantMap(), params);
}

void Events::cacheImage(QNetworkReply *reply) {
    QImage image;
    image.loadFromData(reply->readAll());
    reply->deleteLater();
    
    QVariantMap event = m_events.takeFirst();
    
    if ((!image.isNull()) && (QDir().mkpath(IMAGE_CACHE_PATH)) && (image.save(m_imageFileName))) {
        event["imageList"] = QStringList(m_imageFileName);
    }
    
    addItemToEventFeed(event);
    nextEvent();
}

void Events::parseDailymotionFeed() {
    if (m_dailymotionRequest->status() != QDailymotion::ResourcesRequest::Ready) {
        nextFeed();
        return;
    }
    
    QVariantList videos = m_dailymotionRequest->result().toMap().value("list").toList();
    const QDateTime lastUpdated = m_feeds.at(m_index).lastUpdated;
    const QString sourceName = QString("cutetube_events_dailymotion_%1_%2").arg(m_feeds.at(m_index).feedType)
                                                                           .arg(m_feeds.at(m_index).query);
    
    while (!videos.isEmpty()) {
        const QVariantMap video = videos.takeFirst().toMap();
        const QDateTime date = QDateTime::fromTime_t(video.value("created_time").toLongLong());
        
        if (date <= lastUpdated) {
            break;
        }
        
        QVariantMap event;
        event["icon"] = DEFAULT_ICON;
        event["title"] = video.value("title");
        event["body"] = video.value("description").toString().remove(QRegExp("<[^>]*>"));
        event["imageList"] = QStringList(video.value("thumbnail_120_url").toString());
        event["video"] = true;
        event["footer"] = video.value("owner.screenname");
        event["timestamp"] = date.toString(Qt::ISODate);
        event["url"] = video.value("url");
        event["sourceName"] = sourceName;
        event["sourceDisplayName"] = "cuteTube";
        
        if (m_useCustomAction) {
            event["action"] = m_action.arg(event.value("url").toString());
        }
        
        m_events << event;
    }
    
    m_feeds[m_index].lastUpdated = QDateTime::currentDateTime();
    nextFeed();
}

void Events::parseVimeoFeed() {
    if (m_vimeoRequest->status() != QVimeo::ResourcesRequest::Ready) {
        nextFeed();
        return;
    }
    
    QVariantList videos = m_vimeoRequest->result().toMap().value("data").toList();
    const QDateTime lastUpdated = m_feeds.at(m_index).lastUpdated;
    const QString sourceName = QString("cutetube_events_vimeo_%1_%2").arg(m_feeds.at(m_index).feedType)
                                                                     .arg(m_feeds.at(m_index).query);
    
    while (!videos.isEmpty()) {
        const QVariantMap video = videos.takeFirst().toMap();
        const QDateTime date = QDateTime::fromString(video.value("created_time").toString(), Qt::ISODate);
        
        if (date <= lastUpdated) {
            break;
        }
        
        QVariantMap event;
        event["icon"] = DEFAULT_ICON;
        event["title"] = video.value("name");
        event["body"] = video.value("description").toString().remove(QRegExp("<[^>]*>"));
        event["imageList"] = QStringList(QString("https://i.vimeocdn.com/video/%1_100x75.jpg")
                                         .arg(video.value("pictures").toMap().value("uri").toString().section('/', -1)));
        event["video"] = true;
        event["footer"] = video.value("user").toMap().value("name");
        event["timestamp"] = date.toString(Qt::ISODate);
        event["url"] = QString("https://vimeo.com/%1").arg(video.value("uri").toString().section('/', -1));
        event["sourceName"] = sourceName;
        event["sourceDisplayName"] = "cuteTube";
        
        if (m_useCustomAction) {
            event["action"] = m_action.arg(event.value("url").toString());
        }
        
        m_events << event;
    }
    
    m_feeds[m_index].lastUpdated = QDateTime::currentDateTime();
    nextFeed();
}

void Events::parseYouTubeFeed() {
    if (m_youtubeRequest->status() != QYouTube::ResourcesRequest::Ready) {
        nextFeed();
        return;
    }
    
    QVariantList videos = m_youtubeRequest->result().toMap().value("items").toList();
    const QDateTime lastUpdated = m_feeds.at(m_index).lastUpdated;
    const QString sourceName = QString("cutetube_events_youtube_%1_%2").arg(m_feeds.at(m_index).feedType)
                                                                       .arg(m_feeds.at(m_index).query);
    
    while (!videos.isEmpty()) {
        const QVariantMap video = videos.takeFirst().toMap();
        const QVariantMap snippet = video.value("snippet").toMap();
        const QDateTime date = QDateTime::fromString(snippet.value("publishedAt").toString(), Qt::ISODate);
        
        if (date <= lastUpdated) {
            break;
        }
        
        QVariantMap event;
        event["icon"] = DEFAULT_ICON;
        event["title"] = snippet.value("title");
        event["body"] = snippet.value("description").toString().remove(QRegExp("<[^>]*>"));
        event["imageList"] = QStringList(snippet.value("thumbnails").toMap().value("default").toMap()
                                         .value("url").toString());
        event["video"] = true;
        event["footer"] = snippet.value("channelTitle");
        event["timestamp"] = date.toString(Qt::ISODate);
        event["url"] = QString("https://www.youtube.com/watch?v=%1")
                       .arg(video.value("id").toMap().value("videoId").toString());
        event["sourceName"] = sourceName;
        event["sourceDisplayName"] = "cuteTube";
        
        if (m_useCustomAction) {
            event["action"] = m_action.arg(event.value("url").toString());
        }
        
        m_events << event;
    }
    
    m_feeds[m_index].lastUpdated = QDateTime::currentDateTime();
    nextFeed();
}

void Events::readAction() {
    QFile file(ACTION_FILE);
    
    if (file.open(QFile::ReadOnly | QFile::Text)) {
        m_action = QString::fromUtf8(file.readLine());
        file.close();
    }
    
    if (!m_action.isEmpty()) {
        m_action.replace("%U", "%1");
        m_useCustomAction = true;
    }
    else {
        m_useCustomAction = false;
    }
}

void Events::readFeeds() {
    QFile file(FEEDS_FILE);
    
    if (file.open(QFile::ReadOnly | QFile::Text)) {
        while (!file.atEnd()) {
            QStringList split = QString::fromUtf8(file.readLine()).split("\t", QString::SkipEmptyParts);
            
            if (split.size() > 4) {
                Feed feed;
                feed.service = split.takeFirst();
                feed.feedType = split.takeFirst();
                feed.query = split.takeFirst();
                feed.maxResults = split.takeFirst().toInt();
                feed.lastUpdated = QDateTime::fromString(split.takeFirst(), Qt::ISODate);
                m_feeds << feed;
            }
        }
        
        file.close();
    }
}

void Events::writeFeeds() {
    QFile file(FEEDS_FILE);
    
    if (file.open(QFile::WriteOnly | QFile::Text)) {
        for (int i = 0; i < m_feeds.size(); i++) {
            file.write(QString("%1\t%2\t%3\t%4\t%5\n").arg(m_feeds.at(i).service).arg(m_feeds.at(i).feedType)
                                                      .arg(m_feeds.at(i).query).arg(m_feeds.at(i).maxResults)
                                                      .arg(m_feeds.at(i).lastUpdated.toString(Qt::ISODate)).toUtf8());
        }
        
        file.close();
    }
}
