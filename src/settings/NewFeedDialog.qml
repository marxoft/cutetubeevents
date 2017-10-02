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

Dialog {
    id: root
    
    property string service
    property string feedType
    property string query
    property int maxResults
    
    title: qsTr("New feed")
    height: Math.min(360, flow.height + platformStyle.paddingMedium)
    
    Flickable {
        id: flickable
        
        anchors {
            left: parent.left
            right: acceptButton.left
            rightMargin: platformStyle.paddingMedium
            top: parent.top
            bottom: parent.bottom
        }
        contentHeight: flow.height
        horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
        
        Flow {
            id: flow
        
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            spacing: platformStyle.paddingMedium
        
            ValueButton {
                id: serviceButton
            
                width: parent.width
                text: qsTr("Service")
                pickSelector: serviceSelector
            }
        
            ValueButton {
                id: feedTypeButton
            
                width: parent.width
                text: qsTr("Feed type")
                pickSelector: feedTypeSelector
            }
        
            Label {
                width: parent.width
                text: feedTypeSelector.currentIndex == 1 ? qsTr("Channel") : qsTr("Query")
            }
        
            TextField {
                id: queryField
            
                width: parent.width - findUserButton.width - parent.spacing
            }
        
            Button {
                id: findUserButton
            
                text: qsTr("Find channel")
                enabled: (feedTypeSelector.currentIndex == 1) && (queryField.text)
                onClicked: {
                    switch (serviceSelector.currentIndex) {
                    case 0:
                        youtubeDialog.createObject(root);
                        break;
                    case 1:
                        dailymotionDialog.createObject(root);
                        break;
                    case 2:
                        vimeoDialog.createObject(root);
                        break;
                    default:
                        break;
                    }
                }
            }
        
            Label {
                width: parent.width
                text: qsTr("Maximum results")
            }
        
            SpinBox {
                id: maxResultsField
            
                width: parent.width
                minimum: 5
                maximum: 50
                value: 20
            }
        }
    }
    
    Button {
        id: acceptButton
        
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        style: DialogButtonStyle {}
        text: qsTr("Done")
        enabled: queryField.text != ""
        onClicked: {
            root.service = serviceSelector.currentValueText.toLowerCase();
            root.query = queryField.text;
            root.feedType = feedTypeSelector.currentValueText.toLowerCase();
            root.maxResults = maxResultsField.value;
            root.accept();
        }
    }
    
    ListPickSelector {
        id: serviceSelector
        
        model: ["YouTube", "Dailymotion", "Vimeo"]
    }
    
    ListPickSelector {
        id: feedTypeSelector
        
        model: ["Search", "Channel"]
    }
    
    Component {
        id: youtubeDialog
        
        YouTubeUserDialog {
            onAccepted: queryField.text = userId
            onStatusChanged: if (status == DialogStatus.Closed) destroy();
            Component.onCompleted: {
                open();
                reload(queryField.text);
            }
        }
    }
    
    Component {
        id: dailymotionDialog
        
        DailymotionUserDialog {
            onAccepted: queryField.text = userId
            onStatusChanged: if (status == DialogStatus.Closed) destroy();
            Component.onCompleted: {
                open();
                reload(queryField.text);
            }
        }
    }
    
    Component {
        id: vimeoDialog
        
        VimeoUserDialog {
            onAccepted: queryField.text = userId
            onStatusChanged: if (status == DialogStatus.Closed) destroy();
            Component.onCompleted: {
                open();
                reload(queryField.text);
            }
        }
    }

    contentItem.states: State {
        name: "Portrait"
        when: screen.currentOrientation == Qt.WA_Maemo5PortraitOrientation

        AnchorChanges {
            target: flickable
            anchors.right: parent.right
        }

        PropertyChanges {
            target: flickable
            anchors.rightMargin: 0
        }

        PropertyChanges {
            target: acceptButton
            width: parent.width
        }

        PropertyChanges {
            target: root
            height: Math.min(680, flow.height + acceptButton.height + platformStyle.paddingMedium * 2)
        }
    }
}
