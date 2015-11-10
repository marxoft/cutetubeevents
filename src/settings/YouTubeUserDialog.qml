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
import QYouTube 1.0 as QYouTube

Dialog {
    id: root
    
    property string userId
    
    function reload(query) {
        userModel.list("/search", ["snippet"], {}, {type: "channel", maxResults: 20, q: query, order: "relevance",
                                                    safeSearch: "none"});
    }
    
    height: 350
    title: qsTr("Select channel")
    showProgressIndicator: userModel.status == QYouTube.ResourcesRequest.Loading
    
    ListView {
        id: view
        
        anchors.fill: parent
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        model: QYouTube.ResourcesModel {
            id: userModel
            
            apiKey: "AIzaSyDhIlkLzHJKDCNr6thsjlQpZrkY3lO_Uu4"
        }
        delegate: ListItem {
            Image {
                id: image
                
                anchors {
                    left: parent.left
                    leftMargin: platformStyle.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                width: 64
                height: 64
                source: snippet.thumbnails["default"].url
                smooth: true
            }
            
            Label {
                id: label
                
                anchors {
                    left: image.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    margins: platformStyle.paddingMedium
                }
                elide: Text.ElideRight
                text: snippet.title
            }
            
            onClicked: {
                root.userId = id.channelId;
                root.accept();
            }
        }        
    }
    
    Label {
        anchors.centerIn: parent
        font.pointSize: platformStyle.fontSizeXLarge
        color: platformStyle.disabledTextColor
        text: qsTr("No channels")
        visible: (userModel.status != QYouTube.ResourcesRequest.Loading) && (userModel.count == 0)
    }
}
