//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Hash2Pics
//import MultyCoreLibrary

let wirelessRequestImagesAmount = 10

class ReceiveAllDetailsPresenter: NSObject, ReceiveSumTransferProtocol, SendWalletProtocol {

    var receiveAllDetailsVC: ReceiveAllDetailsViewController?
    
    var cryptoSum: String?
    var cryptoName: String?
    var fiatSum: String?
    var fiatName: String?
    var wirelessRequestImage: UIImage? {
        didSet {
            if wirelessRequestImage != nil {
                receiveAllDetailsVC?.hidedImage.image = wirelessRequestImage
            }
        }
    }
    
    var walletAddress = "" {
        didSet {
            if wallet != nil || walletAddress.isEmpty {
                walletAddress = wallet!.address
            }
            
            generateWirelessRequestImage()
        }
    }
    
    var wallet: UserWalletRLM? {
        didSet {
            if wallet != nil {
                qrBlockchainString = BlockchainType.create(wallet: wallet!).qrBlockchainString
               
                if oldValue != wallet {
                    if wallet!.addresses.count > 0 {
                        walletAddress = wallet!.addresses.last!.address
                        
                        if walletAddress.isEmpty {
                            walletAddress = wallet!.address
                        }
                    } else {
                        walletAddress = ""
                        
                        if wallet!.address.isEmpty {
                            walletAddress = wallet!.address
                        }
                    }
                }
            }
        }
    }
    
    var qrBlockchainString = String()
    
    var blockWirelessActivityUpdating = false
    
    var isOpenByDL = false
    var dlParams: NSDictionary?
    
    func viewControllerViewDidLoad() {
        let _ = BLEManager.shared
    }
    
    func viewControllerViewWillAppear() {
        viewWillAppear()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActive(notification:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate(notification:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(notification:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangedBluetoothReachability(notification:)), name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
    }
    
    func viewWillAppear() {
        receiveAllDetailsVC?.updateSearchingAnimation()
        
        blockWirelessActivityUpdating = false
        startWirelessReceiverActivity()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didUpdateTransaction(notification:)), name: Notification.Name("transactionUpdated"), object: nil)
        if wallet!.isMultiSig {
            NotificationCenter.default.addObserver(self, selector: #selector(self.updateMSTransaction(notification:)), name: Notification.Name("msTransactionUpdated"), object: nil)
        }
    }
    
    func viewDidAppear() {
        generateWirelessRequestImage()
    }
    
    func viewControllerViewWillDisappear() {
        viewWillDisappear()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
    }
    
    func viewWillDisappear() {
        stopWirelessReceiverActivity()
        blockWirelessActivityUpdating = true
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name("transactionUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("msTransactionUpdated"), object: nil)
    }
    
    func cancelViewController() {
        if self.receiveAllDetailsVC!.option == .wireless {
            stopWirelessReceiverActivity()
        }
        
        self.receiveAllDetailsVC?.tabBarController?.selectedIndex = 0
        self.receiveAllDetailsVC?.navigationController?.popToRootViewController(animated: false)
    }
    
    func transferSum(cryptoAmount: String, cryptoCurrency: String, fiatAmount: String, fiatName: String) {
        self.cryptoSum = cryptoAmount
        self.cryptoName = cryptoCurrency
        self.fiatSum = fiatAmount
        self.fiatName = fiatName
        
        self.receiveAllDetailsVC?.setupUIWithAmounts()
        
        if self.receiveAllDetailsVC!.option == .wireless {
            startWirelessReceiverActivity()
        }
    }
    
    func sendWallet(wallet: UserWalletRLM) {
        self.wallet = wallet
        self.receiveAllDetailsVC?.updateUIWithWallet()
        
        if self.receiveAllDetailsVC!.option == .wireless {
            startWirelessReceiverActivity()
        }
    }
    
    func didChangeReceivingOption() {
        switch self.receiveAllDetailsVC!.option {
        case .qrCode:
            stopWirelessReceiverActivity()
            break
            
        case .wireless:
            let bluetoothEnabled = BLEManager.shared.reachability == .reachable || BLEManager.shared.reachability == .unknown
            receiveAllDetailsVC?.updateUIForBluetoothState(bluetoothEnabled)
            startWirelessReceiverActivity()
            break
        }
    }
    
    func openByDL(params: NSDictionary) {
        let cryptoAmountString = params["amount"] as! String
        self.cryptoSum = BigInt(cryptoAmountString).cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
        self.cryptoName = wallet?.cryptoName
        self.fiatSum = "5"
        self.fiatName = "$"
        
        self.receiveAllDetailsVC?.setupUIWithAmounts()
//        self.receiveAllDetailsVC?.option = .wireless
        self.receiveAllDetailsVC?.receiveViaWirelessScanAction(Any.self)
//        startWirelessReceiverActivity()
    }
    
    private func handleBluetoothReachability() {
        if self.receiveAllDetailsVC?.option == .wireless {
            let reachability = BLEManager.shared.reachability
            
            if reachability == .notReachable {
                receiveAllDetailsVC?.updateUIForBluetoothState(false)
                if !blockWirelessActivityUpdating {
                    stopWirelessReceiverActivity()
                }
            } else if reachability == .reachable {
                receiveAllDetailsVC?.updateUIForBluetoothState(true)
                if !blockWirelessActivityUpdating {
                    startWirelessReceiverActivity()
                }
            }
        }
    }
    
    private func generateWirelessRequestImage() {
        guard let diameter = receiveAllDetailsVC?.hidedImage.frame.size.width else {
            return
        }
        wirelessRequestImage = PictureConstructor().createPicture(diameter: diameter, seed: walletAddress)
//
//        DataManager.shared.getAccount { (account, error) in
//            if account != nil {
//
        
//                let userID = account!.userID
//                let userCode = self.userCodeForUserID(userID: userID)
//                if let value = UInt32(userCode, radix: 16) {
//                    let imageNumber = Int(value)%wirelessRequestImagesAmount
//
//                    self.receiveAllDetailsVC?.updateWirelessTransactionImage()
//                }
//            }
//        }
    }
    
    private func startWirelessReceiverActivity() {
        if self.receiveAllDetailsVC!.option == .wireless {
            let reachability = BLEManager.shared.reachability
            if reachability == .reachable {
                DataManager.shared.getAccount { (account, error) in
                    if account != nil {
                        let userCode = self.userCodeForWalletID(self.walletAddress)
                        if userCode != nil {
                            self.becomeReceiver(userID: account!.userID, userCode: userCode!)
                            self.shareUserCode(code: userCode!)
                        }
                    }
                }
            }
        }
    }
    
    private func stopWirelessReceiverActivity() {
        if BLEManager.shared.isAdvertising {
            stopSharingUserCode()
        }
        cancelBecomeReceiver()
    }
    
    private func shareUserCode(code : String) {
        if !BLEManager.shared.isAdvertising {
            BLEManager.shared.advertise(userId: code)
        }
    }
    
    func userCodeForWalletID(_ walletID : String) -> String? {
        return walletID.convertToUserCode
    }
    
    private func stopSharingUserCode() {
        if BLEManager.shared.isAdvertising {
            BLEManager.shared.stopAdvertising()
        }
    }
    
    private func becomeReceiver(userID : String, userCode : String) {
        guard self.wallet != nil else {
            return
        }
        
        let blockchainType = BlockchainType.create(wallet: self.wallet!)
        let currencyID = self.wallet!.chain
        let networkID = blockchainType.net_type
        let address = walletAddress
        let amount = cryptoSum != nil ? cryptoSum!.convertCryptoAmountStringToMinimalUnits(in: Blockchain.init(rawValue: currencyID.uint32Value)).stringValue : "0"
        
        DataManager.shared.socketManager.becomeReceiver(receiverID: userID, userCode: userCode, currencyID: currencyID.intValue, networkID: networkID, address: address, amount: amount)
    }
    
    private func cancelBecomeReceiver() {
        DataManager.shared.socketManager.stopReceive()
    }
    
    @objc private func didChangedBluetoothReachability(notification: Notification) {
        DispatchQueue.main.async {
            self.handleBluetoothReachability()
        }
    }
    
    @objc private func updateMSTransaction(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            let userInfo = notification.userInfo
            let tx = notification.userInfo?["transaction"] as? NSDictionary
            
            if tx != nil {
                let payloadInfo = tx!["payload"] as? [AnyHashable : Any]
                
                guard let txStatus = tx!["type"] as? Int,
                    txStatus == SocketMessageType.multisigTxPaymentRequest.rawValue,
                    let addressTo = payloadInfo?["To"] as? String,
                    let addressFrom = payloadInfo?["From"] as? String else {
                        return
                }
                
                guard let amount = payloadInfo?["Amount"] as? String else {
                        return
                }
                
                let amountString = self.convertAddressDataToString(amount, 60, 1)
                if addressTo == self.walletAddress {
                    self.receiveAllDetailsVC?.presentDidReceivePaymentAlert(address: addressFrom, amount: amountString)
                    self.receiveAllDetailsVC?.sendAnalyticsEvent(screenName: KFReceiveScreen, eventName: KFTransactionReceived)
                }
            }
        }
    }
    
    @objc private func didUpdateTransaction(notification: Notification) {
        DispatchQueue.main.async {
            let userInfo = notification.userInfo
            if userInfo != nil {
                let notifictionMsg = userInfo!["NotificationMsg"] as! NSDictionary
                guard let txStatus = notifictionMsg["transactionType"] as? Int,
                    let addressTo = notifictionMsg["to"] as? String,
                    let addressFrom = notifictionMsg["from"] as? String else {
                    return
                }
                
                guard let amount = notifictionMsg["amount"] as? String,
                    let currencyID = notifictionMsg["currencyid"] as? UInt32,
                    let networkID = notifictionMsg["networkid"] as? UInt32 else {
                    return
                }
                
                let amountString = self.convertAddressDataToString(amount, currencyID, networkID)
                if txStatus == TxStatus.MempoolIncoming.rawValue && addressTo == self.walletAddress {
                    self.receiveAllDetailsVC?.presentDidReceivePaymentAlert(address: addressFrom, amount: amountString)
                    self.receiveAllDetailsVC?.sendAnalyticsEvent(screenName: KFReceiveScreen, eventName: KFTransactionReceived)
                }
            }
        }
    }
    
    func convertAddressDataToString(_ amountString: String,_ currencyID: UInt32,_ networkID: UInt32) -> String {
        let blockchainType = BlockchainType.create(currencyID: currencyID, netType: networkID)
        let cryptoValueString = BigInt(amountString).cryptoValueString(for: blockchainType.blockchain)
        
        return cryptoValueString + " " + blockchainType.shortName
    }
    
    @objc private func applicationWillResignActive(notification: Notification) {
        viewWillDisappear()
    }
    
    @objc private func applicationWillTerminate(notification: Notification) {
        viewWillDisappear()
    }
    
    @objc private func applicationDidBecomeActive(notification: Notification) {
        viewWillAppear()
    }
}
