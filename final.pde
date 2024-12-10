// Source:
#include <WaspXBeeZB.h>
#include <WaspSensorEvent_v30.h>
#include <WaspFrame.h>
float temperature;
float humidity;
float pressure;

// known coordinator's operating 64-bit PAN ID to set
uint8_t  PANID[8] = {0x12, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88};

// node Id to be searched
char nodeToSearch[] = "Coordinator";

// variable to store searched Destination MAC Address
uint8_t mac[8]; 

// define variable
uint8_t error;



void setup()
{ 
  // init USB port
  USB.ON();
  USB.println(F("Source node (TX node)"));
  
  USB.println(F("\n------------------------------------"));
  USB.print(F("Node ID to search:"));
  USB.println(nodeToSearch);
  USB.println(F("------------------------------------"));
  

  // init XBee
  xbeeZB.ON();

  // set NI (Node Identifier)
  xbeeZB.setNodeIdentifier("node_TX");
  
 // Disable Coordinator mode
  xbeeZB.setCoordinator(DISABLED);

  // check at command flag
  if (xbeeZB.error_AT == 0)
  {
    USB.println(F("1. Coordinator mode disabled"));
  }
  else
  {
    USB.println(F("1. Error while disabling Coordinator mode"));
  }
  

  //Set PANID
  xbeeZB.setPAN(PANID);

  // check at command flag
  if (xbeeZB.error_AT == 0)
  {
    USB.println(F("2. PANID set OK"));
  }
  else
  {
    USB.println(F("2. Error while setting PANID"));
  }

  // Set channels to be scanned before creating network
  ///////////////////////////////////////////////
  // channels from 0x0B to 0x18 (0x19 and 0x1A are excluded)
  /* Range:[0x0 to 0x3FFF]
    Channels are scpedified as a bitmap where depending on
    the bit a channel is selected --> Bit (Channel):
     0 (0x0B)  4 (0x0F)  8 (0x13)   12 (0x17)
     1 (0x0C)  5 (0x10)  9 (0x14)   13 (0x18)
     2 (0x0D)  6 (0x11)  10 (0x15)
     3 (0x0E)  7 (0x12)   11 (0x16)    */
  xbeeZB.setScanningChannels(0x3F, 0xFF);

  // check at command flag
  if (xbeeZB.error_AT == 0)
  {
    USB.println(F("3. Scanning channels set OK"));
  }
  else
  {
    USB.println(F("3. Error while setting 'Scanning channels'"));
  }

  // save XBee values in memory
  xbeeZB.writeValues();
  
  //////////////////////////
  // check XBee's network parameters
  //////////////////////////
  USB.println(F("Check Network parameters:"));  
  checkNetworkParams();

}



void loop()
{   
  ////////////////////////////////////////
  // search node
  ////////////////////////////////////////

  error = xbeeZB.nodeSearch(nodeToSearch, mac);

  if( error == 0 )
  {
    USB.print(F("\nNode found!\nmac:"));
    USB.printHex( mac[0] );
    USB.printHex( mac[1] );
    USB.printHex( mac[2] );
    USB.printHex( mac[3] );
    USB.printHex( mac[4] );
    USB.printHex( mac[5] );
    USB.printHex( mac[6] );
    USB.printHex( mac[7] );
  }
  else 
  {
    USB.print(F("nodeSearch() did not find any node")); 
  }
  USB.println();


  ////////////////////////////////////////
  // send a packet to the searched node
  ////////////////////////////////////////
   temperature = Events.getTemperature();
   humidity = Events.getHumidity();
   pressure = Events.getPressure();

    // Create new frame
    frame.createFrame(ASCII);
    frame.addSensor(SENSOR_STR, temperature);
    frame.addSensor(SENSOR_STR, humidity);
    frame.addSensor(SENSOR_STR, pressure);
    frame.showFrame();
    error = xbeeZB.send(mac, frame.buffer, frame.length);
    if (error == 0) {
        USB.println(F("Frame2 sent successfully"));
    } else {
        USB.println(F("Error sending frame2"));
    }
    // Wait for 5 seconds
    delay(5000);

  if( error == 0 )
  {
    // send XBee packet
    error = xbeeZB.send( mac, "Message_from_TX_node" );   

    // check TX flag
    if( error == 0 )
    {
      USB.println(F("send ok"));
    

      // blink green LED
      Utils.blinkGreenLED();
    }
    else 
    {
      USB.println(F("send error"));

      // blink red LED
      Utils.blinkRedLED();
    }
  }

  // wait   
  delay(3000);  

}  

/*******************************************
 *
 *  checkNetworkParams - Check operating
 *  network parameters in the XBee module
 *
 *******************************************/
void checkNetworkParams()
{
  // 1. get operating 64-b PAN ID
  xbeeZB.getOperating64PAN();

  // 2. wait for association indication
  xbeeZB.getAssociationIndication();
 
  while( xbeeZB.associationIndication != 0 )
  { 
    delay(2000);
    
    // get operating 64-b PAN ID
    xbeeZB.getOperating64PAN();

    USB.print(F("operating 64-b PAN ID: "));
    USB.printHex(xbeeZB.operating64PAN[0]);
    USB.printHex(xbeeZB.operating64PAN[1]);
    USB.printHex(xbeeZB.operating64PAN[2]);
    USB.printHex(xbeeZB.operating64PAN[3]);
    USB.printHex(xbeeZB.operating64PAN[4]);
    USB.printHex(xbeeZB.operating64PAN[5]);
    USB.printHex(xbeeZB.operating64PAN[6]);
    USB.printHex(xbeeZB.operating64PAN[7]);
    USB.println();     
    
    xbeeZB.getAssociationIndication();
  }

  USB.println(F("\nJoined a network!"));

  // 3. get network parameters 
  xbeeZB.getOperating16PAN();
  xbeeZB.getOperating64PAN();
  xbeeZB.getChannel();

  USB.print(F("operating 16-b PAN ID: "));
  USB.printHex(xbeeZB.operating16PAN[0]);
  USB.printHex(xbeeZB.operating16PAN[1]);
  USB.println();

  USB.print(F("operating 64-b PAN ID: "));
  USB.printHex(xbeeZB.operating64PAN[0]);
  USB.printHex(xbeeZB.operating64PAN[1]);
  USB.printHex(xbeeZB.operating64PAN[2]);
  USB.printHex(xbeeZB.operating64PAN[3]);
  USB.printHex(xbeeZB.operating64PAN[4]);
  USB.printHex(xbeeZB.operating64PAN[5]);
  USB.printHex(xbeeZB.operating64PAN[6]);
  USB.printHex(xbeeZB.operating64PAN[7]);
  USB.println();

  USB.print(F("channel: "));
  USB.printHex(xbeeZB.channel);
  USB.println();

}

// Coordinator:
#include <WaspXBeeZB.h>

// Coordinator's 64-bit PAN ID to set
uint8_t PANID[8] = { 0x12, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88 };
char nodeID[] = "Coordinator";
uint8_t error;

// Arrays to store temperature, humidity, and pressure values
float tempValues[3] = {0};
float humValues[3] = {0};
float pressValues[3] = {0};
int frameCount = 0;

void setup() {
    // Init USB
    USB.ON();
    USB.println(F("ZB_Coordinator"));

    // Init XBee
    xbeeZB.ON();
    delay(1000);
    xbeeZB.setNodeIdentifier(nodeID);
    
    // Set Coordinator Enable
    xbeeZB.setCoordinator(ENABLED);
    if (xbeeZB.error_AT == 0) {
        USB.println(F("1. Coordinator Enabled OK"));
    } else {
        USB.println(F("1. Error while enabling Coordinator mode"));
    }

    // Set PANID
    xbeeZB.setPAN(PANID);
    if (xbeeZB.error_AT == 0) {
        USB.println(F("2. PANID set OK"));
    } else {
        USB.println(F("2. Error while setting PANID"));
    }

    // Set scanning channels
    xbeeZB.setScanningChannels(0x03, 0xFF);
    if (xbeeZB.error_AT == 0) {
        USB.println(F("3. Scanning channels set OK"));
    } else {
        USB.println(F("3. Error while setting 'Scanning channels'"));
    }

    xbeeZB.writeValues();
    delay(10000);
    USB.println();
    USB.println(F("Check Network parameters:"));  
    checkNetworkParams();
}

void loop() {
    // Receive packets and parse each frame
    for (int i = 0; i < 3; i++) {
        uint8_t error = xbeeZB.receivePacketTimeout(10000);
        if (error == 0) {
            USB.print(F("Data: "));  
            USB.println(xbeeZB._payload, xbeeZB._length);
            parseFrame(xbeeZB._payload, xbeeZB._length);
        } else {
            USB.print(F("Error receiving a Frame:"));
            USB.println(error, DEC);     
        }
    }
    printAveragesAndStdDevs();
}

void parseFrame(uint8_t* payload, int length) {
    if (length > 0) {
        // Extract temperature, humidity, and pressure from payload
        float temperature = atof((char*)payload+14 ); // Adjust based on frame structure
        float humidity = atof((char*)payload +12);    
        float pressure = atof((char*)payload +9);     
        
        // Store values in arrays, using frameCount for cycling through
        tempValues[frameCount %3] = temperature;
        humValues[frameCount %3] = humidity;
        pressValues[frameCount%3] = pressure;

        // Increment frame count
        frameCount++;
    }
}

void printAveragesAndStdDevs() {
    float sumTemp = 0, sumHum = 0, sumPress = 0;
    float sumTempSq = 0, sumHumSq = 0, sumPressSq = 0;
    int validFrames = 0;

    USB.println(F("\nCollected Values for Last 3 Frames:"));
    for (int i = 0; i < 5; i++) {
        if (tempValues[i] != 0 || humValues[i] != 0 || pressValues[i] != 0) {
            USB.print(F("Frame "));
            USB.print(i + 1);
            USB.print(F(": Temp = "));
            USB.print(tempValues[i]);
            USB.print(F(", Hum = "));
            USB.print(humValues[i]);
            USB.print(F(", Press = "));
            USB.println(pressValues[i]);
            
            sumTemp += tempValues[i];
            sumHum += humValues[i];
            sumPress += pressValues[i];
            sumTempSq += tempValues[i] * tempValues[i];
            sumHumSq += humValues[i] * humValues[i];
            sumPressSq += pressValues[i] * pressValues[i];

            validFrames++; // Increment valid frame count
        }
    }

        float avgTemp = sumTemp / validFrames;
        float avgHum = sumHum / validFrames;
        float avgPress = sumPress / validFrames;

        float stdDevTemp = sqrt((sumTempSq / validFrames) - (avgTemp * avgTemp));
        float stdDevHum = sqrt((sumHumSq / validFrames) - (avgHum * avgHum));
        float stdDevPress = sqrt((sumPressSq / validFrames) - (avgPress * avgPress));

        USB.println(F("\nAverages:"));
        USB.print(F("Average Temp: "));
        USB.println(avgTemp);
        USB.print(F("Average Hum: "));
        USB.println(avgHum);
        USB.print(F("Average Press: "));
        USB.println(avgPress);

        USB.println(F("\nStandard Deviations:"));
        USB.print(F("Std Dev Temp: "));
        USB.println(stdDevTemp);
        USB.print(F("Std Dev Hum: "));
        USB.println(stdDevHum);
        USB.print(F("Std Dev Press: "));
        USB.println(stdDevPress);

}

void checkNetworkParams() {
    // Get operating 64-b PAN ID
    xbeeZB.getOperating64PAN();
    // Wait for association indication
    xbeeZB.getAssociationIndication();
    
    while (xbeeZB.associationIndication != 0) { 
        delay(2000);
        xbeeZB.getOperating64PAN();

        USB.print(F("operating 64-b PAN ID: "));
        for (int i = 0; i < 8; i++) {
            USB.printHex(xbeeZB.operating64PAN[i]);
        }
        USB.println();     
        xbeeZB.getAssociationIndication();
    }

    USB.println(F("\nJoined a network!"));
    // Get network parameters 
    xbeeZB.getOperating16PAN();
    xbeeZB.getOperating64PAN();
    xbeeZB.getChannel();

    USB.print(F("operating 16-b PAN ID: "));
    USB.printHex(xbeeZB.operating16PAN[0]);
    USB.printHex(xbeeZB.operating16PAN[1]);
    USB.println();

    USB.print(F("operating 64-b PAN ID: "));
    for (int i = 0; i < 8; i++) {
        USB.printHex(xbeeZB.operating64PAN[i]);
    }
    USB.println();

    USB.print(F("channel: "));
    USB.printHex(xbeeZB.channel);
    USB.println();
}

