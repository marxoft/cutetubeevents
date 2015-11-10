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
import QDailymotion 1.0 as QDailymotion

Dialog {
    id: root
    
    property string userId
    
    function reload(query) {
        userModel.list("/users", {limit: 20, search: query, sort: "relevance", "family_filter": false},
                       ["id", "avatar_60_url", "screenname"]);
    }
    
    height: 350
    title: qsTr("Select channel")
    showProgressIndicator: userModel.status == QDailymotion.ResourcesRequest.Loading
    
    ListView {
        id: view
        
        anchors.fill: parent
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        model: QDailymotion.ResourcesModel {
            id: userModel
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
                source: avatar_60_url
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
                text: screenname
            }
            
            onClicked: {
                root.userId = id;
                root.accept();
            }
        }        
    }
    
    Label {
        anchors.centerIn: parent
        font.pointSize: platformStyle.fontSizeXLarge
        color: platformStyle.disabledTextColor
        text: qsTr("No channels")
        visible: (userModel.status != QDailymotion.ResourcesRequest.Loading) && (userModel.count == 0)
    }
}
