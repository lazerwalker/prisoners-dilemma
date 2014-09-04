@import MultipeerConnectivity;
#import <ReactiveCocoa/ReactiveCocoa.h>

#import "ViewController.h"

static NSString * const ServiceType = @"mlw-prisoner";

typedef NS_ENUM(NSInteger, Choice) {
    ChoiceNotMade = 0,
    ChoiceCooperate,
    ChoiceDefect
};

@interface ViewController ()<MCBrowserViewControllerDelegate, MCAdvertiserAssistantDelegate, MCSessionDelegate>

@property (readwrite, nonatomic, assign) NSInteger roundNumber;
@property (readwrite, nonatomic, assign) NSInteger yourScore;
@property (readwrite, nonatomic, assign) NSInteger theirScore;

@property (readwrite, nonatomic, assign) Choice yourLatestChoice;
@property (readwrite, nonatomic, assign) Choice theirLatestChoice;

@property (readwrite, nonatomic, strong) MCSession *session;
@property (readwrite, nonatomic, strong) MCAdvertiserAssistant *assistant;

@property (weak, nonatomic) IBOutlet UILabel *roundLabel;
@property (weak, nonatomic) IBOutlet UILabel *yourScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *theirScoreLabel;

@property (readwrite, nonatomic, strong) UIAlertView *waitingAlertView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [self startNextRound];

    // Start advertising device
    UIDevice *device = [UIDevice currentDevice];
    MCPeerID *peer = [[MCPeerID alloc] initWithDisplayName:device.name];
    self.session = [[MCSession alloc] initWithPeer:peer];
    self.session.delegate = self;
    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:ServiceType
                                                          discoveryInfo:nil
                                                                session:self.session];
    self.assistant.delegate = self;


    // UI
    self.waitingAlertView = [[UIAlertView alloc] init];
    self.waitingAlertView.message = @"Waiting for the other player to make their choice...";

    RAC(self, roundLabel.text) = [RACObserve(self, roundNumber) map:^id(NSNumber *number) {
        return [NSString stringWithFormat:@"Round %@", number];
    }];

    RAC(self, yourScoreLabel.text) = [RACObserve(self, yourScore) map:^id(NSNumber *number) {
        return number.stringValue;
    }];

    RAC(self, theirScoreLabel.text) = [RACObserve(self, theirScore) map:^id(NSNumber *number) {
        return number.stringValue;
    }];

    // Game state
    RACSignal *youMoved = [[RACObserve(self, yourLatestChoice)
        ignore:@(ChoiceNotMade)]
        doNext:^(NSNumber *choiceNum) {
            [self sendLatestMove];

            if (self.theirLatestChoice == ChoiceNotMade) {
                [self.waitingAlertView show];
            }
        }];

    RACSignal *theyMoved = [RACObserve(self, theirLatestChoice)
                            ignore:@(ChoiceNotMade)];

    [[youMoved zipWith:theyMoved] subscribeNext:^(RACTuple *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.waitingAlertView dismissWithClickedButtonIndex:0 animated:NO];
        });

        [self updateScore:result];
        [self showResults:result];
        [self startNextRound];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self startMatchmaking];
}

#pragma mark - game logic
- (void)updateScore:(RACTuple *)tuple {
    Choice you = [tuple.first integerValue];
    Choice they = [tuple.second integerValue];
    if (you == ChoiceCooperate) {
        if (they == ChoiceCooperate) {
            self.yourScore += 2;
            self.theirScore += 2;
        } else {
            self.yourScore -= 1;
            self.theirScore += 3;
        }
    } else {
        if (they == ChoiceCooperate) {
            self.yourScore += 3;
            self.theirScore -= 1;
        } else {
            // Nothing happens
        }
    }
}

- (void)showResults:(RACTuple *)result {
    NSDictionary *mapping = @{
      @(ChoiceCooperate) : @"cooperate",
      @(ChoiceDefect) : @"defect"
    };

    NSString *you = mapping[result.first];
    NSString *they = mapping[result.second];

    UIAlertView *resultsAlert = [[UIAlertView alloc] init];
    resultsAlert.title = @"Round Over";
    resultsAlert.message = [NSString stringWithFormat:@"You chose to %@. The other player chose to %@.", you, they];
    [resultsAlert addButtonWithTitle:@"OK"];

    dispatch_async(dispatch_get_main_queue(), ^{
        [resultsAlert show];
    });
}

- (void)startNextRound {
    self.yourLatestChoice = ChoiceNotMade;
    self.theirLatestChoice = ChoiceNotMade;
    self.roundNumber++;
}

#pragma mark - Networking
- (void)sendLatestMove {
    NSInteger round = self.roundNumber;
    if (self.yourLatestChoice == ChoiceDefect) {
        round *= -1;
    }

    NSData *data = [NSData dataWithBytes:&round length:sizeof(round)];
    NSError *error;

    [self.session sendData:data
                   toPeers:self.session.connectedPeers
                  withMode:MCSessionSendDataReliable
                     error:&error];
}

- (void)startMatchmaking {
    if (self.session.connectedPeers.count == 0) {
        [self.assistant start];

        MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:ServiceType
                                                                                        session:self.session];
        browser.delegate = self;
        [self presentViewController:browser animated:YES completion:nil];
    }
}

- (void)stopMatchmaking {
    [self.assistant stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Events
- (IBAction)didTapCooperateButton:(id)sender {
    self.yourLatestChoice = ChoiceCooperate;
}

- (IBAction)didTapDefectButton:(id)sender {
    self.yourLatestChoice = ChoiceDefect;
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self stopMatchmaking];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self stopMatchmaking];
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    if (state == MCSessionStateConnected) {
        [self stopMatchmaking];
    } else if (state == MCSessionStateNotConnected) {
        [self startMatchmaking];
    }
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSInteger round;
    [data getBytes:&round length:sizeof(round)];

    if (ABS(round) != self.roundNumber) return;

    self.theirLatestChoice = (round > 0 ? ChoiceCooperate : ChoiceDefect);
}

#pragma mark - MCSessionDelegate no-ops
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {}
@end
