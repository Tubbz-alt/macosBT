//
//  MacosBT.h
//  MacosBluetooth
//
//  Created by Bernd Porr on 11/02/2020.
//  Copyright © 2020 Bernd Porr. Apache License
//

#ifndef MacosBT_h
#define MacosBT_h

#include <thread>

class MacosBT {
public:
    void clearText();
    void sendMessage(char* dataToSend, int len);
    void dataRec(const char *text);
    void start();
    void stop();
    void closeConnection();
    
    static void run(MacosBT *MacosBT);
    
private:
    void discover();
    void *rfcommDevice;
    void *rfcommchannel;
    std::thread* uthread = NULL;
    int running = 0;
};


#endif /* MacosBT_h */
