//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

private typealias LocalizeDelegate = Constants

struct Constants {
    
    //Assets screen
    struct AssetsScreen {
        static let createWalletString = "Create wallet"
        static let backupButtonHeight = CGFloat(44)
        static let backupAssetsOffset = CGFloat(25)
        static let leadingAndTrailingOffset = CGFloat(16)
    }
    
    struct ETHWalletScreen {
        static let topCellHeight = CGFloat(331)
        static let blockedCellDifference = CGFloat(60) // difference in table cell sizes in case existing/non existing blocked amount on wallet
        static let collectionCellDifference = CGFloat(137) // difference in sizes btw table cell and collection cell
    }
    
    //StoryboardStrings
    struct Storyboard {
        //Assets
        static let createWalletVCSegueID = "createWalletVC"
        static let contactVCSegueID = "contactVC"
        static let waitingMembersSettingsVCSegueID = "waitingMembersSettings"
    }
    
    struct UserDefaults {
        //Config constants
        static let apiVersionKey =         "apiVersion"
        static let hardVersionKey =        "hardVersion"
        static let softVersionKey =        "softVersion"
        static let serverTimeKey =         "serverTime"
        static let stocksKey =             "stocks"
        static let btcDonationAddressesKey =  "donationAddresses"
    }
    
    struct DataManager {
        static let btcTestnetDonationAddress =  "mnUtMQcs3s8kSkSRXpREVtJamgUCWpcFj4"
        
        static let availableBlockchains = [
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN.rawValue, netType: BITCOIN_NET_TYPE_MAINNET.rawValue),
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN.rawValue, netType: BITCOIN_NET_TYPE_TESTNET.rawValue),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_RINKEBY.rawValue)),
        ]
        
        static let availableMultisigBlockchains = [BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
                                                   BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_RINKEBY.rawValue))]
        
        static let donationBlockchains = [
//            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
//            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN_LIGHTNING.rawValue,netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_GOLOS.rawValue,            netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_STEEM.rawValue,            netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_BITSHARES.rawValue,        netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN_CASH.rawValue,     netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_LITECOIN.rawValue,         netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_DASH.rawValue,             netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM_CLASSIC.rawValue, netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_ERC20.rawValue,            netType: 0),
        ]
        
        struct RealmManager {
            static let leastSchemaVersionAfterCoreLibPrivateKeyFix = 31
        }
    }
    
    struct BigIntSwift {
        static let oneETHInWeiKey = BigInt("1000000000000000000") // 1 ETH = 10^18 Wei
        static let oneHundredFinneyKey = BigInt("10000000000000000") // 10^{-2} ETH
        
        static let oneBTCInSatoshiKey = BigInt("100000000") // 1 BTC = 10^8 Satoshi
        static let oneCentiBitcoinInSatoshiKey = BigInt("1000000") // 10^{-2} BTC
    }
    
    struct BlockchainString {
        static let bitcoinKey = "bitcoin"
        static let ethereumKey = "ethereum"
    }
    
    struct CustomFee {
        static let defaultBTCCustomFeeKey = 2
        static let defaultETHCustomFeeKey = 1 // in GWei
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}

let defaultDelimeter = "," as Character

let screenSize = UIScreen.main.bounds
let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height

//Devices Heights
let heightOfXSMax    : CGFloat = 896.0
let heightOfX        : CGFloat = 812.0
let heightOfPlus     : CGFloat = 736.0
let heightOfStandard : CGFloat = 667.0
let heightOfFive     : CGFloat = 568.0
let heightOfiPad     : CGFloat = 480.0
//

let infoPlist = Bundle.main.infoDictionary!

//createWallet, WalletSettingd
let maxNameLength = 25

//brick view
let segmentsCountUp : Int  = 7
let segmentsCountDown : Int  = 8
let upperSizes : [CGFloat] = [0, 35, 79, 107, 151, 183, 218, 253]
let downSizes : [CGFloat] = [0, 23, 40, 53, 81, 136, 153, 197, 249]

let nanosecondsInOneSecond = 1000000000.0

let statuses = ["createdTx", "fromSocketTx", "incoming in mempool", "spend in mempool", "incoming in block", "spend in block", "in block confirmed", "rejected block"]

var isNeedToAutorise = false
var isViewPresented = false

func convertSatoshiToBTCString(sum: UInt64) -> String {
    return (Double(sum) / pow(10, 8)).fixedFraction(digits: 8) + " BTC"
}

func convertSatoshiToBTC(sum: Double) -> String {
    return (sum / pow(10, 8)).fixedFraction(digits: 8)
}

func convertBTCStringToSatoshi(sum: String) -> UInt64 {
    return UInt64(sum.toStringWithZeroes(precision: 8))!
}

func convertBTCToSatoshi(sum: String) -> Double {
    return sum.convertStringWithCommaToDouble() * pow(10, 8)
}

func shakeView(viewForShake: UIView) {
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: viewForShake.center.x - 10, y: viewForShake.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: viewForShake.center.x + 10, y: viewForShake.center.y))
    
    viewForShake.layer.add(animation, forKey: "position")
//    self.viewWithCircles.layer.add(animation, forKey: "position")
}

let HUDFrame = CGRect(x: screenWidth / 2 - 70,   // width / 2
                      y: screenHeight / 2 - 60,  // height / 2
                      width: 145,
                      height: 120)

let idOfInapps = ["io.multy.addingActivity5", "io.multy.addingCharts5", "io.multy.addingContacts5",
                  "io.multy.addingDash5", "io.multy.addingEthereumClassic5", "io.multy.addingExchange5",
                  "io.multy.exchangeStocks", "io.multy.importWallet5", "io.multy.addingLitecoin5",
                  "io.multy.addingPortfolio5", "io.multy.addingSteemit5", "io.multy.wirelessScan5",
                  "io.multy.addingBCH5", "io.multy.estimationCurrencies5", "io.multy.addingEthereum5"]

let idOfInapps50 = ["io.multy.addingActivity50", "io.multy.addingCharts50", "io.multy.addingContacts50",
                  "io.multy.addingDash50", "io.multy.addingEthereumClassic50", "io.multy.addingExchange50",
                  "io.multy.exchangeStocks50", "io.multy.importWallet50", "io.multy.addingLitecoin50",
                  "io.multy.addingPortfolio50", "io.multy.addingSteemit50", "io.multy.wirelessScan50",
                  "io.multy.addingBCH50", "io.multy.estimationCurrencie50", "io.multy.addingEthereum50"]

enum WalletType : Int {
    case
        Created =       0,
        Multisig =      1,
        Imported =      2
}

enum TxStatus : Int {
    case
        Rejected =                   0,
        MempoolIncoming =            1,
        BlockIncoming =              2,
        MempoolOutcoming =           3,
        BlockOutcoming =             4,
        BlockConfirmedIncoming =     5,
        BlockConfirmedOutcoming =    6,
        BlockMethodInvocationFail =  7,
        RejectedIncoming =           8,
        RejectedOutgoing =           9
}

enum SocketMessageType : Int {
    case
        multisigJoin =              1,
        multisigLeave =             2,
        multisigDelete =            3,
        multisigKick =              4,
        multisigCheck =             5,
        multisigView =              6,
        multisigDecline =           7,
        multisigWalletDeploy =      8,
        multisigTxPaymentRequest =  9,
        multisigTxIncoming =        10,
        multisigTxConfirm =         11,
        multisigTxRevoke =          12,
        resyncCompleted =           13
}

enum Result<Value, Error: StringProtocol> {
    case success(Value)
    case failure(Error)
}

enum MultiSigWalletStatus: Int {
    case
        multisigStatusWaitingForJoin =  1,
        multisigStatusAllJoined =       2,
        multisigStatusDeployPending =   3,
        multisigStatusRejected =        4,
        multisigStatusDeployed =        5
}

enum MultisigOwnerTxStatus: Int {
    case
    msOwnerStatusWaiting   = 0,
    msOwnerStatusSeen      = 1,
    msOwnerStatusConfirmed = 2,
    msOwnerStatusDeclined  = 3
}

let minSatoshiInWalletForDonate: UInt64 = 10000 //10k minimun sum in wallet for available donation
let minSatoshiToDonate: UInt64          = 5000  //5k minimum sum to donate

let minimumAmountForMakeEthTX = BigInt("\(900_000_000_000_000)") // == 10 cent 16.10.2018

//API REST constants
//let apiUrl = "http://88.198.47.112:2278/"//"http://192.168.0.121:7778/"

//
//let shortURL = "api.multy.io"
//let apiUrl = "https://\(shortURL)/"
//let socketUrl = "wss://\(shortURL)/"

let shortURL = "api.multy.io"
let apiUrl = "https://\(shortURL)/"
let socketUrl = "wss://\(shortURL)/"

//stage
//let shortURL = "148.251.42.107/"
//let apiUrl = "http://\(shortURL)"
//let socketUrl = "ws://\(shortURL)"

//JACK
//let shortURL = "192.168.31.146"
//let apiUrl = "http://\(shortURL):6778/"
//let socketUrl = "ws://\(shortURL):6780/"
//let socketUrl = "ws://192.168.31.147:6780"
//let socketUrl = "http://88.198.47.112:2280"
let apiUrlTest = "http://192.168.0.123:6778/"
let nonLocalURL = "http://88.198.47.112:7778/"

// Bluetooth
let BluetoothSettingsURL_iOS9 = "prefs:root=Bluetooth"
let BluetoothSettingsURL_iOS10 = "App-Prefs:root=Bluetooth"

let inviteCodeCount = 45

let dappDLTitle = "Dragonereum"
let magicReceiveDL = "magicReceive"
