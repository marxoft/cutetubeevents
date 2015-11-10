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

import QtQuick 1.0
import org.hildon.components 1.0
import org.hildon.utils 1.0

Dialog {
    id: root
    
    title: "cuteTube Events"
    height: 350
    
    ListView {
        id: view
        
        anchors {
            left: parent.left
            right: button.left
            rightMargin: platformStyle.paddingMedium
            top: parent.top
            bottom: parent.bottom
        }
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        model: ListModel {
            id: feedsModel
        }
        delegate: ListItem {
            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: platformStyle.paddingMedium
                }
                elide: Text.ElideRight
                text: service + " | " + feedType + " | " + query
            }
            
            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: platformStyle.paddingMedium
                }
                elide: Text.ElideRight
                font.pointSize: platformStyle.fontSizeSmall
                color: platformStyle.secondaryTextColor
                text: qsTr("Updated on") + " " + lastUpdated
            }
            
            onClicked: contextMenu.popup()
            onPressAndHold: contextMenu.popup()
        }
        
        Label {
            anchors.centerIn: parent
            font.pointSize: platformStyle.fontSizeXLarge
            color: platformStyle.disabledTextColor
            text: qsTr("No feeds")
            visible: (root.status == DialogStatus.Open) && (feedsModel.count == 0)
        }
        
        Menu {
            id: contextMenu
            
            MenuItem {
                text: qsTr("Remove")
                onTriggered: {
                    feed.removeItemsBySourceName(feedsModel.get(view.currentIndex).sourceName);
                    feedsModel.remove(view.currentIndex);
                    internal.writeFeeds();
                }
            }
        }
    }
    
    DialogButtonStyle {
        id: buttonStyle
    }

    Button {
        id: button
        
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        style: buttonStyle
        text: qsTr("New")
        onClicked: feedDialog.createObject(root)
    }
    
    Directory {
        id: dir
        
        path: "/home/user/.local/share/data/cutetubeevents/"
    }
    
    File {
        id: file
        
        fileName: "/home/user/.local/share/data/cutetubeevents/feeds"
    }
    
    QtObject {
        id: internal
                
        function readFeeds() {
            feedsModel.clear();
            
            if (file.open(File.ReadOnly | File.Text)) {                
                while (!file.atEnd) {
                    var line = file.readLine().toString().replace("\n", "").split("\t");
                    
                    if (line.length > 4) {
                        feedsModel.append({"service": line[0], "feedType": line[1], "query": line[2],
                                           "maxResults": line[3], "lastUpdated": line[4],
                                           "sourceName": "cutetube_events_" + line[0] + "_" + line[1] + "_" + line[2]});
                    }
                }
                
                file.close();
            }
        }
        
        function writeFeeds() {
            if ((dir.mkpath(dir.path)) && (file.open(File.WriteOnly | File.Text))) {
                for (var i = 0; i < feedsModel.count; i++) {
                    var feed = feedsModel.get(i);
                    file.write(feed.service + "\t" + feed.feedType + "\t" + feed.query + "\t" + feed.maxResults + "\t"
                               + feed.lastUpdated + "\n");
                }
                
                file.close();
            }
        }
    }
    
    Component {
        id: feedDialog
        
        NewFeedDialog {
            onAccepted: {
                feedsModel.append({"service": service, "feedType": feedType, "query": query, "maxResults": maxResults,
                                   "lastUpdated": "1970-01-01T00:00:00",
                                   "sourceName": "cutetube_events_" + service + "_" + feedType + "_" + query});
                internal.writeFeeds();
            }
            onStatusChanged: if (status == DialogStatus.Closed) destroy();
            Component.onCompleted: open()
        }
    }
    
    onStatusChanged: if (status == DialogStatus.Opening) internal.readFeeds();
}
    