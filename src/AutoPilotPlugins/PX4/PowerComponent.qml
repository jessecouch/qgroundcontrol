/*=====================================================================

 QGroundControl Open Source Ground Control Station

 (c) 2009 - 2015 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>

 This file is part of the QGROUNDCONTROL project

 QGROUNDCONTROL is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 QGROUNDCONTROL is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with QGROUNDCONTROL. If not, see <http://www.gnu.org/licenses/>.

 ======================================================================*/

/// @file
///     @brief Battery, propeller and magnetometer settings
///     @author Gus Grubba <mavlink@grubba.com>

import QtQuick 2.2
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2

import QGroundControl.FactSystem 1.0
import QGroundControl.FactControls 1.0
import QGroundControl.Palette 1.0
import QGroundControl.Controls 1.0
import QGroundControl.ScreenTools 1.0
import QGroundControl.Controllers 1.0

QGCView {
    id:             rootQGCView
    viewComponent:  view

    Component {
        id: view

        QGCViewPanel {
            id: viewPanel

            QGCPalette { id: palette; colorGroupEnabled: enabled }

            width:  600
            height: 600
            color:  palette.window

            property int firstColumnWidth: 220
            property int textEditWidth:    80

            property Fact battNumCells:     controller.getParameterFact(-1, "BAT_N_CELLS")
            property Fact battHighVolt:     controller.getParameterFact(-1, "BAT_V_CHARGED")
            property Fact battLowVolt:      controller.getParameterFact(-1, "BAT_V_EMPTY")
            property Fact battVoltLoadDrop: controller.getParameterFact(-1, "BAT_V_LOAD_DROP")

            property alias battHigh: battHighRow
            property alias battLow:  battLowRow

            function getBatteryImage()
            {
                switch(battNumCells.value) {
                    case 1:  return "/qml/PowerComponentBattery_01cell.svg";
                    case 2:  return "/qml/PowerComponentBattery_02cell.svg"
                    case 3:  return "/qml/PowerComponentBattery_03cell.svg"
                    case 4:  return "/qml/PowerComponentBattery_04cell.svg"
                    case 5:  return "/qml/PowerComponentBattery_05cell.svg"
                    case 6:  return "/qml/PowerComponentBattery_06cell.svg"
                    default: return "/qml/PowerComponentBattery_01cell.svg";
                }
            }

            function drawArrowhead(ctx, x, y, radians)
            {
                ctx.save();
                ctx.beginPath();
                ctx.translate(x,y);
                ctx.rotate(radians);
                ctx.moveTo(0,0);
                ctx.lineTo(5,10);
                ctx.lineTo(-5,10);
                ctx.closePath();
                ctx.restore();
                ctx.fill();
            }

            function drawLineWithArrow(ctx, x1, y1, x2, y2)
            {
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
                var rd = Math.atan((y2 - y1) / (x2 - x1));
                rd += ((x2 > x1) ? 90 : -90) * Math.PI/180;
                drawArrowhead(ctx, x2, y2, rd);
            }

            PowerComponentController {
                id:         controller
                factPanel:  viewPanel

                onOldFirmware:          showMessage("ESC Calibration", "QGroundControl cannot perform ESC Calibration with this version of firmware. You will need to upgrade to a newer firmware.", StandardButton.Ok)
                onNewerFirmware:        showMessage("ESC Calibration", "QGroundControl cannot perform ESC Calibration with this version of firmware. You will need to upgrade QGroundControl.", StandardButton.Ok)
                onBatteryConnected:     showMessage("ESC Calibration", "Performing calibration. This will take a few seconds..", 0)
                onCalibrationFailed:    showMessage("ESC Calibration failed", errorMessage, StandardButton.Ok)
                onCalibrationSuccess:   showMessage("ESC Calibration", "Calibration complete. You can disconnect your battery now if you like.", StandardButton.Ok)
                onConnectBattery:       showMessage("ESC Calibration", "WARNING: Props must be removed from vehicle prior to performing ESC calibration.\n\nConnect the battery now and calibration will begin.", 0)
                onDisconnectBattery:    showMessage("ESC Calibration failed", "You must disconnect the battery prior to performing ESC Calibration. Disconnect your battery and try again.", StandardButton.Ok)
            }

            Column {
                anchors.fill: parent
                spacing: 10

                QGCLabel {
                    text: "POWER CONFIG"
                    font.pointSize: ScreenTools.largeFontPointSize
                }

                QGCLabel {
                    text: "Battery"
                    color: palette.text
                    font.pointSize: ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    width: parent.width
                    height: 120
                    color: palette.windowShade

                    Column {
                        id: batteryColumn
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: (parent.x + 20)

                        Row {
                            spacing: 10
                            Column {
                                id: voltageCol
                                spacing: 10
                                Row {
                                    spacing: 10
                                    QGCLabel { text: "Number of Cells (in Series)"; width: firstColumnWidth; anchors.baseline: cellsField.baseline}
                                    FactTextField {
                                        id: cellsField
                                        width: textEditWidth
                                        fact: battNumCells
                                        showUnits: true
                                    }
                                }
                                Row {
                                    id: battHighRow
                                    spacing: 10
                                    QGCLabel { text: "Full Voltage (per cell)"; width: firstColumnWidth; anchors.baseline: battHighField.baseline}
                                    FactTextField {
                                        id: battHighField
                                        width: textEditWidth
                                        fact: battHighVolt
                                        showUnits: true
                                    }
                                }
                                Row {
                                    id: battLowRow
                                    spacing: 10
                                    QGCLabel { text: "Empty Voltage (per cell)"; width: firstColumnWidth; anchors.baseline: battLowField.baseline}
                                    FactTextField {
                                        id: battLowField
                                        width: textEditWidth
                                        fact: battLowVolt
                                        showUnits: true
                                    }
                                }
                            }
                            Canvas {
                                id: arrows
                                height: voltageCol.height
                                width: 40
                                antialiasing: true
                                Connections {
                                    target: ScreenTools
                                    onRepaintRequestedChanged: {
                                        arrows.requestPaint();
                                    }
                                }
                                onPaint: {
                                    var y0 = voltageCol.mapFromItem(battHigh, 0, battHigh.height / 2).y;
                                    var y1 = voltageCol.mapFromItem(battLow,  0, battLow.height  / 2).y;
                                    var context = getContext("2d");
                                    context.reset();
                                    context.strokeStyle = palette.button;
                                    context.fillStyle   = palette.button;
                                    drawLineWithArrow(context, 0, y0, width, height * 0.25);
                                    drawLineWithArrow(context, 0, y1, width, height * 0.85);
                                }
                            }
                            QGCColoredImage {
                                height:   voltageCol.height
                                width:    voltageCol.height * 0.75
                                source:   getBatteryImage();
                                fillMode: Image.PreserveAspectFit
                                smooth:   true
                                color:    palette.button
                                cache:    false
                            }
                            Item { width: 20; height: 1; }
                            Column {
                                spacing: 10
                                anchors.verticalCenter: parent.verticalCenter
                                Row {
                                    spacing: 10
                                    QGCLabel {
                                        text: "Battery Max:"
                                        color: palette.text
                                        width: 80
                                    }
                                    QGCLabel {
                                        text: (battNumCells.value * battHighVolt.value).toFixed(1) + ' V'
                                        color: palette.text
                                    }
                                }
                                Row {
                                    spacing: 10
                                    QGCLabel {
                                        text: "Battery Min:"
                                        color: palette.text
                                        width: 80
                                    }
                                    QGCLabel {
                                        text: (battNumCells.value * battLowVolt.value).toFixed(1) + ' V'
                                        color: palette.text
                                    }
                                }
                            }
                        }
                    }
                }

                QGCLabel {
                    text:           "ESC Calibration"
                    font.pointSize: ScreenTools.mediumFontPointSize
                }

                Rectangle {
                    width:              parent.width
                    height:             80
                    color:              palette.windowShade

                    Column {
                        anchors.margins:    10
                        anchors.fill:       parent
                        spacing:            10

                        QGCLabel {
                            text: "WARNING: Props must be removed from vehicle prior to performing ESC calibration."
                        }

                        QGCButton {
                            text:       "Calibrate"
                            onClicked:  controller.calibrateEsc()
                        }
                    }
                }

                /*
                 * This is disabled for now
                Row {
                    width: parent.width
                    spacing: 30
                    visible: showAdvanced.checked
                    Column {
                        spacing: 10
                        width: (parent.width / 2) - 5
                        QGCLabel {
                            text: "Propeller Function"
                            color: palette.text
                            font.pointSize: ScreenTools.fontPointFactor * (20);
                        }
                        Rectangle {
                            width: parent.width
                            height: 160
                            color: palette.windowShade
                        }
                    }
                    Column {
                        spacing: 10
                        width: (parent.width / 2) - 5
                        QGCLabel {
                            text: "Magnetometer Distortion"
                            color: palette.text
                            font.pointSize: ScreenTools.fontPointFactor * (20);
                        }
                        Rectangle {
                            width: parent.width
                            height: 160
                            color: palette.windowShade
                        }

                    }
                }
                */

                //-- Advanced Settings
                QGCCheckBox {
                    id: showAdvanced
                    text: "Show Advanced Settings"
                }
                QGCLabel {
                    text: "Advanced Power Settings"
                    color: palette.text
                    font.pointSize: ScreenTools.fontPointFactor * (20);
                    visible: showAdvanced.checked
                }
                Rectangle {
                    width: parent.width
                    height: 40
                    color: palette.windowShade
                    visible: showAdvanced.checked
                    Column {
                        id: advBatteryColumn
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: (parent.x + 20)
                        Row {
                            spacing: 10
                            QGCLabel { text: "Voltage Drop on Full Load (per cell)"; width: firstColumnWidth; anchors.baseline: battDropField.baseline}
                            FactTextField {
                                id: battDropField
                                width: textEditWidth
                                fact: battVoltLoadDrop
                                showUnits: true
                            }
                        }
                    }
                }
            } // Column
        } // QGCViewPanel
    } // Component - view
}
