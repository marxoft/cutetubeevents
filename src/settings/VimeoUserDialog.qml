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
import QVimeo 1.0 as QVimeo

Dialog {
    id: root
    
    property string userId
    
    function reload(query) {
        userModel.list("/users", {per_page: 20, query: query, sort: "relevant"});
    }
    
    height: 350
    title: qsTr("Select channel")
    showProgressIndicator: userModel.status == QVimeo.ResourcesRequest.Loading
    
    ListView {
        id: view
        
        anchors.fill: parent
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        model: QVimeo.ResourcesModel {
            id: userModel
            
            accessToken: "fb5c66ebe6938e858921963f850355a0"
            clientId: "0bf284bf5a0e46630f5097a590a76ef976a94322"
            clientSecret: "7nnZ1OPS13hjKAVhzuXx/4AIdKxmgDNasHkj5QraWWkrNsd6mxYWZG73AKaFUdLzoNWhGA75jSffs+JyAFfi0MiFi1OXnzHsxaL0HCIFpxk0GpZlXcScWmJTHvGGtVv1"
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
                source: "https://i.vimeocdn.com/portrait/" + uri.substring(uri.lastIndexOf("/") + 1) + "_75x75.jpg"
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
                text: name
            }
            
            onClicked: {
                root.userId = uri.substring(uri.lastIndexOf("/") + 1);
                root.accept();
            }
        }
    }
    
    Label {
        anchors.centerIn: parent
        font.pointSize: platformStyle.fontSizeXLarge
        color: platformStyle.disabledTextColor
        text: qsTr("No channels")
        visible: (userModel.status != QVimeo.ResourcesRequest.Loading) && (userModel.count == 0)
    }
}
