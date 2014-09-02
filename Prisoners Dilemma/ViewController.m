@import MultipeerConnectivity;

#import "ViewController.h"

static NSString * const ServiceType = @"mlw-prisoner";

@interface ViewController ()<MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate, MCSessionDelegate>

@property (readwrite, nonatomic, strong) MCSession *session;
@property (readwrite, nonatomic, strong) MCAdvertiserAssistant *assistant;
@end

@implementation ViewController

- (void)viewDidLoad {
    UIDevice *device = [UIDevice currentDevice];
    MCPeerID *peer = [[MCPeerID alloc] initWithDisplayName:device.name];
    self.session = [[MCSession alloc] initWithPeer:peer];
    self.session.delegate = self;

    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:ServiceType
                                                          discoveryInfo:nil
                                                                session:self.session];
    self.assistant.delegate = self;
    [self.assistant start];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.session.connectedPeers.count == 0) {
        MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:@"mlw-prisoner" session:self.session];
        browser.delegate = self;
        [self presentViewController:browser animated:YES completion:nil];
    }
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (state == MCSessionStateConnected) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
