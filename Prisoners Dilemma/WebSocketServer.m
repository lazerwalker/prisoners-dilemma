//
//  WebSocketServer.m
//  Prisoners Dilemma
//
//  Created by Michael Walker on 1/1/18.
//  Copyright © 2018 Mike Lazer-Walker. All rights reserved.
//

#import "WebSocketServer.h"

@implementation WebSocketServer

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)didOpen {
    [super didOpen];

    if (self.socketDelegate) {
        [self.delegate webSocketDidOpen:self];
    }
}

- (void)didReceiveMessage:(NSString *)msg {
    [super didReceiveMessage:msg];

    if (self.socketDelegate) {
        [self.delegate webSocket:self didReceiveMessage:msg];
    }
}

- (void)didClose {
    [super didClose];

    if (self.socketDelegate) {
        [self.delegate webSocketDidClose:self];
    }
}

@end
