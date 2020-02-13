//
//  main.cpp
//  iosBluetooth
//
//  Created by Bernd Porr on 11/02/2020.
//  Copyright © 2020 Bernd Porr. All rights reserved.
//

#include <iostream>
#include "MacosBT.h"

int main(int argc, const char * argv[]) {
    // insert code here...
    std::cout << "Hello, Bluetooth RFcomm reception demo.\n";
    MacosBT ad;
    ad.start();
    getchar();
    ad.stop();
    return 0;
}
