//
//  EnvironmentController.swift
//  StoryGlow
//
//  Created by Varun Narayanswamy on 1/30/20.
//  Copyright © 2020 Varun Narayanswamy. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import RxLifxApi
import RxLifx
import LifxDomain
import AVFoundation


class EnvironmentController: UIViewController, AVAudioPlayerDelegate{
    
    var scrollView = UIScrollView()
    var contentView = UIView()
    var storyIndex = Int() //index that holds the current story number
    var sceneIndex = Int() //index that holds the scene number within that story
    var playerMod = [playerModel](repeating: playerModel(), count: 6) //each environmentController has an array of players so that we can
    var audioPlayer: AVAudioPlayer?
    let audioSession = AVAudioSession.sharedInstance() //used inorder to play sound at setup volume

    var playingArray = [Bool](repeating: Bool(false), count: 6) //array of booleans used to determining pausing and playing
    var soundButtonArray = [UIButton]() //Array of 6 buttons
    
    //UI Items
    var SoundButton1 = UIButton()
    var SoundButton2 = UIButton()
    var SoundButton3 = UIButton()
    var SoundButton4 = UIButton()
    var SoundButton5 = UIButton()
    var SoundButton6 = UIButton()
    
    let SegmentedControl = UISegmentedControl(items : ["Edit Mode" , "Presentation Mode"])
    var StackView1 = UIStackView()
    var StackView2 = UIStackView()
    
    var ColorWheelView = UIImageView()
    var ColorWheel = UIImage()
    var colorWheelOnOffButton = UIButton()
    
    let startTextField =  UITextField(frame: CGRect(x: 100, y: 100, width: 200, height: 30))
    let endTextField =  UITextField(frame: CGRect(x: 100, y: 100, width: 200, height: 30))
    
    let endTextFieldOutline = UIButton()
    let startTextFieldOutline = UIButton()
    
    let lightControlLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let soundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let editTextLabel = UILabel()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
        self.title = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].sceneName
        view.backgroundColor = .black
        scrollViewSetup()
        //setting up Segmented Control
        SegmentedControlConfig()
        setupSoundLabel()
        //setting up the stackviews and images
        SoundButtonSyncing()
        SetupStackView1()
        SetupStackView2()
        editTextConfig()
        setupEditTextLabel()
        setupLightLabel()
        SetupColorWheel()
        
        let imageClickedGesture = UITapGestureRecognizer(target: self, action: #selector(imageTap))
        let imageDragGesture = UIPanGestureRecognizer(target: self, action: #selector(imageTap))
        //Adding gestures to the image to allow color selection
        ColorWheelView.addGestureRecognizer(imageClickedGesture)
        ColorWheelView.addGestureRecognizer(imageDragGesture)
        ColorWheelView.isUserInteractionEnabled = true
        
        // Do any additional setup after loading the view.
    }
    
    func scrollViewSetup()
    {
        let margin = view.safeAreaLayoutGuide
        self.view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: margin.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        
        self.scrollView.addSubview(contentView)
        contentView.backgroundColor = .black
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        print(view.frame.height)
        contentView.heightAnchor.constraint(equalToConstant: 780).isActive = true
    }
    
    //this viewdidappear is used to add colors and sounds after swiping data model
    override func viewDidAppear(_ animated: Bool) {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let scene = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex]
        //get color value from data model. Color is initialized to white
        let previousColor = UIColor(red: scene.red, green: scene.green, blue: scene.blue, alpha: scene.alpha)
        previousColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) //setup colors as HSBK colors and set light colors
        let color = HSBK(hue: UInt16(65535*hue), saturation: UInt16(65535*saturation), brightness: UInt16(65535*brightness), kelvin: 0)
        colorWheelOnOffButton.backgroundColor = previousColor
        for i in IntroPage.lightsStruct.lightArray{
            let setColor = LightSetColorCommand.create(light: i, color: color, duration: 0)
            setColor.fireAndForget()
        }
        if (IntroPage.lightsStruct.lightsOn == true){
            colorWheelOnOffButton.setBackgroundImage(UIImage(named: "onLight"), for: .normal)
        }
        else{
            colorWheelOnOffButton.setBackgroundImage(UIImage(named: "offLight"), for: .normal)
        }
        
        //readding sounds to buttons on swiping
        for n in 0...5{
            if (GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundName == "")
            {
                soundButtonArray[n].setImage(UIImage(named: "add.png"), for: .normal)
                GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n] = GlobalVar.SoundAffects(soundName: "", soundVal: "")
            }
    soundButtonArray[n].setTitle(GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundName, for: .normal)
            let red = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundColorRed
            let green = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundColorGreen
            let blue = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundColorBlue
            if (blue != 0 && green == 0){
                print(blue)
                soundButtonArray[n].setTitleColor(.white, for: .normal)
            }
            else
            {
                soundButtonArray[n].setTitleColor(.black, for: .normal)
            }
            soundButtonArray[n].backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
            if (GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundName != ""){
                print("in viewdidappear\(GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[n].soundName)")
                soundButtonArray[n].setImage(UIImage(named: ""), for: .normal)
                soundButtonArray[n].interactions = []
                let interaction = UIContextMenuInteraction(delegate: self)
                soundButtonArray[n].addInteraction(interaction)
            }
        }
        
        //check if story is in present mode or not on swiping
        if PageHolder.editModeStruct.editMode == false{
            startTextField.borderStyle = UITextField.BorderStyle.none
            endTextField.borderStyle = UITextField.BorderStyle.none
            startTextField.text = "Start: " + GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].startText
            endTextField.text = "Stop: " + GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].endText
            startTextField.isUserInteractionEnabled = false
            endTextField.isUserInteractionEnabled = false
            for i in 0...5{
                if GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[i].soundName == ""{
                    soundButtonArray[i].isHidden = true
                }
            }
            SegmentedControl.selectedSegmentIndex = 1
        }else{
            startTextField.borderStyle = UITextField.BorderStyle.none
            endTextField.borderStyle = UITextField.BorderStyle.none
            startTextField.text = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].startText
            endTextField.text = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].endText
            startTextField.isUserInteractionEnabled = true
            endTextField.isUserInteractionEnabled = true
            for i in 0...5{
                soundButtonArray[i].isHidden = false
            }
            SegmentedControl.selectedSegmentIndex = 0
        }
        
    }
    
    //adds soundbuttons to sound array, give them accessibilityIndentifiers for contextMenus and add target functionality
    func SoundButtonSyncing(){
        soundButtonArray.append(SoundButton1)
        soundButtonArray.append(SoundButton2)
        soundButtonArray.append(SoundButton3)
        soundButtonArray.append(SoundButton4)
        soundButtonArray.append(SoundButton5)
        soundButtonArray.append(SoundButton6)
        for i in 0...5{
            soundButtonArray[i].layer.borderColor = UIColor.gray.cgColor
            soundButtonArray[i].layer.borderWidth = 2
            soundButtonArray[i].accessibilityIdentifier = "soundButton\(i+1)"
            soundButtonArray[i].addTarget(self, action: #selector(AddSounds(sender:)), for: .touchUpInside)
            soundButtonArray[i].setImage(UIImage(named: "add.png"), for: .normal)
            soundButtonArray[i].titleLabel?.numberOfLines = 0
            soundButtonArray[i].setTitleColor(.black, for: .normal)
            soundButtonArray[i].backgroundColor = .white
            soundButtonArray[i].layer.cornerRadius = 10
        }
    }
    
    //MARK: Button Control
    //Navigating to sound screen and getting button info
    @objc func AddSounds(sender: UIButton){
        //this is also where we will need to sort out if we are adding or playing the item
        if let buttonIndex = self.soundButtonArray.firstIndex(of: sender){
            //if we are in edit mode
            if PageHolder.editModeStruct.editMode == true{
               let nextScreen = RecordAudioController()//change later
               nextScreen.buttonIndexRec = buttonIndex
               nextScreen.sceneIndexRec = sceneIndex
               nextScreen.storyIndexRec = storyIndex
               nextScreen.title = "Add a Sound Effect"
               navigationController?.pushViewController(nextScreen, animated: true)
            //if we are in present mode
            }else{
            //play sounds
                playSounds(buttonIndex: buttonIndex)
            }
        }
    }
    
    //function that actually plays sound
    func playSounds(buttonIndex:Int){
        //If audio string is an url from freesound
        if GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[buttonIndex].soundVal.contains("https") == true {
            //If player boolean is true and player is playing (boolean may not be needed)
            if (playingArray[buttonIndex] == true && playerMod[buttonIndex].player.timeControlStatus == .playing){
                playerMod[buttonIndex].player.pause()
                playingArray[buttonIndex] = false
            }else{
                let url = URL.init(string:GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[buttonIndex].soundVal) //convert string from data model to url
                let playerItem: AVPlayerItem = AVPlayerItem(url: url!)
                playerMod[buttonIndex].player = AVPlayer(playerItem: playerItem)
                playerMod[buttonIndex].player.volume = 1.0
                let playerLayer = AVPlayerLayer(player: playerMod[buttonIndex].player)
                playerLayer.frame = CGRect(x: 0, y: 0, width: 10, height: 50)
                self.view.layer.addSublayer(playerLayer)
                playingArray[buttonIndex] = true
                playerMod[buttonIndex].player.play()
            }
        }
        //if audio string is a url we recorded
        else{
            //If player boolean is true and player is playing (boolean may not be needed)
            if (playingArray[buttonIndex]==true && audioPlayer?.isPlaying == true){
                audioPlayer?.stop()
            }
            else{
                playingArray[buttonIndex] = true
                let soundUrl = URL(string: GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[buttonIndex].soundVal)
                do {
                    try audioPlayer = AVAudioPlayer(contentsOf: soundUrl!)
                    //set to playback mode for optimal volume
                    try audioSession.setCategory(AVAudioSession.Category.playback)
                    audioPlayer!.delegate = self
                    audioPlayer!.prepareToPlay() // preload audio
                    audioPlayer!.volume = 1.0
                    audioPlayer!.play() //plays audio file
                } catch {
                    print("audioPlayer error")
                }
            }
        }
    }
    
    //text change function
    @objc func textFieldEditingDidChange(){
        GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].startText = startTextField.text!
        GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].endText = endTextField.text!
    }
    
    
    //MARK: Segmented Control
    //Control segmented control
    @objc func indexChanged(_ sender: UISegmentedControl) {
        let EditModeNotification = Notification.Name("editMode")
        NotificationCenter.default.post(Notification(name: EditModeNotification))
        //If switched to presentation mode
        if sender.selectedSegmentIndex == 1{
            startTextField.borderStyle = UITextField.BorderStyle.none
            endTextField.borderStyle = UITextField.BorderStyle.none
            startTextFieldOutline.backgroundColor = UIColor.black
            endTextFieldOutline.backgroundColor = UIColor.black
            endTextField.backgroundColor = UIColor.black
            startTextField.backgroundColor = UIColor.black
            startTextField.textColor = UIColor.white
            endTextField.textColor = UIColor.white
            startTextField.text = "Start: " + GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].startText
            endTextField.text = "Stop: " + GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].endText
            startTextField.isUserInteractionEnabled = false
            endTextField.isUserInteractionEnabled = false
            for i in 0...5{
                if GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[i].soundName == ""{
                    soundButtonArray[i].isHidden = true //hide unused buttons
                }
                soundButtonArray[i].interactions = [] //remove contextMenu interactions
            }
        }
        // if in edit mode load all buttons
        else{
            startTextFieldOutline.backgroundColor = UIColor.white
            endTextFieldOutline.backgroundColor = UIColor.white
            endTextField.backgroundColor = UIColor.white
            startTextField.backgroundColor = UIColor.white
            endTextField.textColor = UIColor.black
            startTextField.textColor = UIColor.black
            startTextField.borderStyle = UITextField.BorderStyle.none
            endTextField.borderStyle = UITextField.BorderStyle.none
            startTextField.text = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].startText
            endTextField.text = GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].endText
            startTextField.isUserInteractionEnabled = true
            endTextField.isUserInteractionEnabled = true
            for i in 0...5{
                soundButtonArray[i].isHidden = false //show buttons
                if (GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].buttonInfo[i].soundName != ""){
                    let interaction = UIContextMenuInteraction(delegate: self)
                    soundButtonArray[i].addInteraction(interaction) //add interactions to buttons that are populated
                }
            }
        }
        
    }
    
    
    
    //MARK:Constraints and Setup
    //configure segmented Control
    func SegmentedControlConfig(){
        SegmentedControl.center = self.view.center
        SegmentedControl.selectedSegmentIndex = 0
        SegmentedControl.addTarget(self, action: #selector(EnvironmentController.indexChanged(_:)), for: .valueChanged)
        SegmentedControl.layer.cornerRadius = 5.0
        SegmentedControl.backgroundColor = UIColor(red:0.84, green:0.36, blue:0.69, alpha:1.00)
        self.contentView.addSubview(SegmentedControl)
        SegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        SegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor , constant: 15).isActive = true
        SegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant:  -15).isActive = true
        SegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true
        SegmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 10).isActive = true
    }
    
    //Adding the edit texts
    func editTextConfig(){
        startTextFieldOutline.backgroundColor = UIColor.white
        endTextFieldOutline.backgroundColor = UIColor.white
        endTextField.backgroundColor = UIColor.white
        startTextField.backgroundColor = UIColor.white
        endTextField.textColor = UIColor.black
        startTextField.textColor = UIColor.black
        startTextField.layer.cornerRadius = 10
        endTextField.layer.cornerRadius = 10
        startTextField.placeholder = "Starting Point"
        startTextField.font = UIFont.systemFont(ofSize: 15)
        startTextField.autocorrectionType = UITextAutocorrectionType.no
        startTextField.keyboardType = UIKeyboardType.default
        startTextField.returnKeyType = UIReturnKeyType.done
        startTextField.clearButtonMode = UITextField.ViewMode.whileEditing;
        startTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        startTextField.delegate = self as? UITextFieldDelegate
        startTextField.addTarget(self, action: #selector(textFieldEditingDidChange), for: UIControl.Event.editingChanged)
        self.contentView.addSubview(startTextField)
        
        endTextField.placeholder = "Stoping Point"
        endTextField.font = UIFont.systemFont(ofSize: 15)
        endTextField.autocorrectionType = UITextAutocorrectionType.no
        endTextField.keyboardType = UIKeyboardType.default
        endTextField.returnKeyType = UIReturnKeyType.done
        endTextField.clearButtonMode = UITextField.ViewMode.whileEditing;
        endTextField.contentVerticalAlignment = UIControl.ContentVerticalAlignment.center
        endTextField.delegate = self as? UITextFieldDelegate
        endTextField.addTarget(self, action: #selector(textFieldEditingDidChange), for: UIControl.Event.editingChanged)
        self.contentView.addSubview(endTextField)
        
        
        endTextField.translatesAutoresizingMaskIntoConstraints = false
        endTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        endTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        endTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        endTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        startTextField.translatesAutoresizingMaskIntoConstraints = false
        startTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15).isActive = true
        startTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15).isActive = true
        startTextField.bottomAnchor.constraint(equalTo: endTextField.topAnchor, constant: -10).isActive = true
        startTextField.heightAnchor.constraint(equalToConstant: 30).isActive = true

    }
    
     //setting up buttons and adding them to stackview1
    func SetupStackView1(){
        contentView.addSubview(StackView1)
        StackView1.addArrangedSubview(SoundButton1)
        StackView1.addArrangedSubview(SoundButton2)
        StackView1.addArrangedSubview(SoundButton3)
        StackView1.axis = .horizontal
        StackView1.alignment = .fill
        StackView1.spacing = 40
        StackView1.distribution = .fillEqually
        StackViewConfig1()
    }
    
    //configuring stackview1's constraints
    func StackViewConfig1(){
        StackView1.translatesAutoresizingMaskIntoConstraints = false
        StackView1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        StackView1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        StackView1.heightAnchor.constraint(equalToConstant: 80).isActive = true
        StackView1.topAnchor.constraint(equalTo: soundLabel.bottomAnchor, constant: 10).isActive = true
    }
    
    //setting up buttons and adding them to stackview2
    func SetupStackView2(){
        contentView.addSubview(StackView2)
        StackView2.addArrangedSubview(SoundButton4)
        StackView2.addArrangedSubview(SoundButton5)
        StackView2.addArrangedSubview(SoundButton6)
        StackView2.axis = .horizontal
        StackView2.alignment = .fill
        StackView2.spacing = 40
        StackView2.distribution = .fillEqually
        StackViewConfig2()
    }
    
    func StackViewConfig2(){
        StackView2.translatesAutoresizingMaskIntoConstraints = false
        StackView2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        StackView2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        StackView2.heightAnchor.constraint(equalToConstant: 80).isActive = true
        StackView2.topAnchor.constraint(equalTo: StackView1.bottomAnchor, constant: 20).isActive = true
    }
    
    func setupSoundLabel(){
        soundLabel.textAlignment = .center
        soundLabel.text = "Sound Board"
        soundLabel.textColor = .white
        soundLabel.font = UIFont.boldSystemFont(ofSize: 20)
        

        self.contentView.addSubview(soundLabel)
        soundLabel.translatesAutoresizingMaskIntoConstraints = false
        soundLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        soundLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        soundLabel.topAnchor.constraint(equalTo: SegmentedControl.bottomAnchor, constant: 10).isActive = true
    }
    
    func setupLightLabel(){
        lightControlLabel.textAlignment = .center
        lightControlLabel.text = "Assign Color to LIFX Bulbs"
        lightControlLabel.textColor = .white
        lightControlLabel.font = UIFont.boldSystemFont(ofSize: 20)

        
        self.contentView.addSubview(lightControlLabel)
        lightControlLabel.translatesAutoresizingMaskIntoConstraints = false
        lightControlLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        lightControlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        lightControlLabel.topAnchor.constraint(equalTo: StackView2.bottomAnchor, constant: 20).isActive = true
    }
    
    func setupEditTextLabel(){
        self.contentView.addSubview(editTextLabel)
        editTextLabel.text = "Mapping to the Book"
        editTextLabel.textAlignment = .center
        editTextLabel.textColor = .white
        editTextLabel.font = UIFont.boldSystemFont(ofSize: 20)
        editTextLabel.translatesAutoresizingMaskIntoConstraints = false
        editTextLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
        editTextLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true
        editTextLabel.bottomAnchor.constraint(equalTo: startTextField.topAnchor, constant: -10).isActive = true

    }
    //configuring stackview2's constraints
    func SetupColorWheel(){
        ColorWheel = UIImage(named: "colorwheel2")!
        ColorWheelView = UIImageView(image: ColorWheel)
        contentView.addSubview(ColorWheelView)
        
        ColorWheelView.translatesAutoresizingMaskIntoConstraints = false
        ColorWheelView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        ColorWheelView.topAnchor.constraint(equalTo: lightControlLabel.bottomAnchor, constant: 10).isActive = true
        //making sure UIImageView is the same size as the image so the CGimage pixels line up with the UIImage pixels
        ColorWheelView.widthAnchor.constraint(equalToConstant: ColorWheel.size.width).isActive = true
        ColorWheelView.heightAnchor.constraint(equalToConstant: ColorWheel.size.height).isActive = true
        
        setupColorWheelOnOff()
    }
    
    //Setting up the Colorwheel image and adding Constraints
    func setupColorWheelOnOff(){
        view.addSubview(colorWheelOnOffButton)
        colorWheelOnOffButton.backgroundColor = .white
        colorWheelOnOffButton.setBackgroundImage(UIImage(named: "onLight"), for: .normal)
        colorWheelOnOffButton.translatesAutoresizingMaskIntoConstraints = false
        colorWheelOnOffButton.centerXAnchor.constraint(equalTo: ColorWheelView.centerXAnchor).isActive = true
        colorWheelOnOffButton.centerYAnchor.constraint(equalTo: ColorWheelView.centerYAnchor).isActive = true
        colorWheelOnOffButton.widthAnchor.constraint(equalTo: ColorWheelView.widthAnchor, multiplier: 1/4).isActive = true
        colorWheelOnOffButton.heightAnchor.constraint(equalTo: ColorWheelView.heightAnchor, multiplier: 1/4).isActive = true
        colorWheelOnOffButton.layer.cornerRadius = ColorWheelView.frame.width/8
        colorWheelOnOffButton.contentMode = .center
        colorWheelOnOffButton.imageView?.contentMode = .scaleAspectFit
        colorWheelOnOffButton.addTarget(self, action: #selector(turnOff), for: .touchUpInside)
        print(ColorWheelView.frame.width)
        colorWheelOnOffButton.clipsToBounds = true
    }
    
    @objc func turnOff(){
        if (IntroPage.lightsStruct.lightsOn == true){
            colorWheelOnOffButton.setBackgroundImage(UIImage(named: "offLight"), for: .normal)
        }
        else{
            colorWheelOnOffButton.setBackgroundImage(UIImage(named: "onLight"), for: .normal)
        }
            NotificationCenter.default.post(Notification(name: Notification.Name("turnLightsOff")))
    }
    
    
    
    //MARK: Image
    //Checks if image is clicked, check the color of the image at the point, change the color of the button and the color of every light. May not be needed with longtap gesture recognizer as well
    @objc func imageTap(recognizer: UITapGestureRecognizer){
        let point = recognizer.location(in: ColorWheelView)
        let point2 = recognizer.location(in: contentView)
        let centerPoint = ColorWheelView.center
        let distance = (pow(centerPoint.x-point2.x, 2) + pow(centerPoint.y-point2.y,2)).squareRoot()
        if (distance>ColorWheelView.frame.width/2-3){
            print("out of circle")
        }
        else{
            let x = Int(point.x)
            let y = Int(point.y)
            
            let RGBcolor = ColorWheel[x,y]
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            if let realColor = RGBcolor{
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                realColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].red = red
                GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].blue = blue
                GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].green = green
                GlobalVar.GlobalItems.storyArray[storyIndex].sceneArray[sceneIndex].alpha = alpha
                //converting color from RGB to HSB
                realColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                //maybe get saturation and brightness
                print("saturation\(saturation)")
                print("brightness \(brightness)")
                //Setting light color
                let color = HSBK(hue: UInt16(65535*hue), saturation: UInt16(65535*saturation), brightness: UInt16(65535*brightness), kelvin: 0)
                
                //Iterating through all lights and changing the color
                //colorView.backgroundColor = realColor
                colorWheelOnOffButton.backgroundColor = realColor
                for i in IntroPage.lightsStruct.lightArray{
                    let setColor = LightSetColorCommand.create(light: i, color: color, duration: 0)
                    setColor.fireAndForget()
                }
            }
        }
    }
    
    
    
    
}

//MARK:Extensions
//This extension gets us the pixel information of the CGimage and converts it into an RGB UIColor
extension UIImage {
    subscript(x: Int, y: Int)-> UIColor?{
        //makes sure that our point is within the range of the image
        guard x>=0 && x<Int(size.width) && y>=0 && y<Int(size.height),
            //converts cgimage data into data for each byte
            let cg = cgImage,
            let provider = cg.dataProvider,
            let providedData = provider.data,
            let pureData = CFDataGetBytePtr(providedData) else{
                return nil
        }
        //converts data into RGBA
        let componentNum = 4
        let pixelData = ((Int(size.width)*y)+x) * componentNum
        let r = CGFloat(pureData[pixelData]) / 255.0
        let g = CGFloat(pureData[pixelData + 1]) / 255.0
        let b = CGFloat(pureData[pixelData + 2]) / 255.0
        let a = CGFloat(pureData[pixelData + 3]) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
            
    }
}

//The setup of the context menu, choosing buttons
extension EnvironmentController: UIContextMenuInteractionDelegate{
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      configurationForMenuAtLocation location: CGPoint)
        -> UIContextMenuConfiguration? {
      return UIContextMenuConfiguration(
        identifier: nil,
        previewProvider: nil,
        actionProvider: { suggestedActions in
            return self.makeContextMenu(interact: interaction)
      })
    }
    
    //Building context menu
    func makeContextMenu(interact: UIContextMenuInteraction) -> UIMenu{
        var buttonIndex = 0
        for i in 0...self.soundButtonArray.count-1{
            if (interact.view?.accessibilityIdentifier == self.soundButtonArray[i].accessibilityIdentifier){
                buttonIndex = i
            }
        }
        let rename = UIAction(title: "rename sound", image: UIImage(systemName: "pencil")){ action in
            let alert = UIAlertController(title: "Choose sound name", message: "Rename your sound", preferredStyle: .alert)
            alert.addTextField()
            let Done = UIAlertAction(title: "Done", style: .default, handler: {_ in
                let answer = alert.textFields![0].text
                if (answer != ""){
                    GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundName = answer!
                    self.soundButtonArray[buttonIndex].setTitle(answer, for: .normal)
                    
                }else{
                    alert.message = "please make a valid story name"
                }
            })
            alert.addAction(Done)
            self.present(alert,animated: true,completion: nil)
        }
        let delete = UIAction(title: "delete sound", image: UIImage(systemName: "trash")){ action in
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundName = ""
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundVal = ""
            self.soundButtonArray[buttonIndex].interactions = []
            self.soundButtonArray[buttonIndex].setTitle("", for: .normal)
        }
        let red = UIAction(title: "red", image: UIImage(named: "red")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .red
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 1.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 0.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 0.0
        }
        let orange = UIAction(title: "orange", image: UIImage(named: "orange")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .orange
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 1.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 0.5
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 0.0
        }
        let yellow = UIAction(title: "yellow", image: UIImage(named: "yellow")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .yellow
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 1.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 1.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 0.0
        }
        let green = UIAction(title: "green", image: UIImage(named: "green")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .green
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 0.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 0.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 1.0
        }
        let blue = UIAction(title: "blue", image: UIImage(named: "blue")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .blue
            self.soundButtonArray[buttonIndex].setTitleColor(.white, for: .normal)
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 0.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 1.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 0.0
        }
        let purple = UIAction(title: "purple", image: UIImage(named: "purple")){_ in
            self.soundButtonArray[buttonIndex].backgroundColor = .purple
            self.soundButtonArray[buttonIndex].setTitleColor(.white, for: .normal)
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorRed = 0.5
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorGreen = 0.0
            GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex].soundColorBlue = 0.5
        }
        var ReplaceActions = [UIAction]()
        for i in 0...5{
            if (i != buttonIndex)
            {
                let replaceItem = UIAction(title: GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[i].soundName, handler: {_ in
                    let currentButtonNameInfo = GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex]
                    let currentName = self.soundButtonArray[buttonIndex].currentTitle
                    let currentNameColor = self.soundButtonArray[buttonIndex].currentTitleColor
                    let currentColor = self.soundButtonArray[buttonIndex].backgroundColor
                    let newButtonName = self.soundButtonArray[i].currentTitle
                    let newButtonNameColor = self.soundButtonArray[i].currentTitleColor
                    let newColor = self.soundButtonArray[i].backgroundColor
                    GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[buttonIndex] = GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[i]
                    GlobalVar.GlobalItems.storyArray[self.storyIndex].sceneArray[self.sceneIndex].buttonInfo[i] = currentButtonNameInfo
                    if (newButtonName == "" || newButtonName == nil){
                        self.soundButtonArray[buttonIndex].setImage(UIImage(named: "add.png"), for: .normal)
                        self.soundButtonArray[buttonIndex].setTitle("", for: .normal)
                        self.soundButtonArray[buttonIndex].interactions = []
                    }
                    else
                    {
                        self.soundButtonArray[buttonIndex].setTitle(newButtonName, for: .normal)
                        self.soundButtonArray[buttonIndex].setTitleColor(newButtonNameColor, for: .normal)
                    }
                    self.soundButtonArray[buttonIndex].backgroundColor = newColor
                    let interaction = UIContextMenuInteraction(delegate: self)
                    self.soundButtonArray[i].addInteraction(interaction)
                    self.soundButtonArray[i].setImage(nil, for: .normal)
                    self.soundButtonArray[i].setTitle(currentName, for: .normal)
                    self.soundButtonArray[i].setTitleColor(currentNameColor, for: .normal)
                    self.soundButtonArray[i].backgroundColor = currentColor
                    
                })
                ReplaceActions.append(replaceItem)
                
            }
        }
        let replace = UIMenu(title: "replace",children: ReplaceActions)
        let setColor = UIMenu(title: "Set Color", image: UIImage(named: "paint") , children: [red,orange,yellow,green,blue,purple])
        let edit = UIMenu(title: "Edit...", children: [rename, delete, setColor,replace])
        let play = UIAction(title: "play", image: UIImage(systemName: "play")){ action in
            self.playSounds(buttonIndex: buttonIndex)
        }
        return UIMenu(title: "Options", children: [edit, play])
    }
}
