//
//  WebSocketServer.h
//  Prisoners Dilemma
//
//  Created by Michael Walker on 1/1/18.
//  Copyright © 2018 Mike Lazer-Walker. All rights reserved.
//

#import <CocoaHTTPServer/WebSocket.h>


@interface WebSocketServer : WebSocket

@property (weak, nonatomic) id<WebSocketDelegate> socketDelegate;

@end
