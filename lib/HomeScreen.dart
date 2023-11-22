import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  ///For DraggableScrollableSheet
  late TabController _tabController;

  ///To see recorded files
  List<String> recordedFiles = [];

  ///For AudioPlayer
  String statusText = "";
  bool isComplete = false;

  ///For DraggableScrollableSheet
  @override
  void initState() {
    super.initState();
    ///for Scroll menu
    // _tabController = TabController(length: 1, vsync: this);
    _tabController = TabController(length: 2, vsync: this);
    ///for Scroll menu
    // Load recorded files when the widget is initialized
    loadRecordedFiles();
  }

  ///For DraggableScrollableSheet
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Recorder"),
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/BGHome.jpg"),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  repeat: ImageRepeat.noRepeat),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 48.0,
                          decoration: BoxDecoration(color: Colors.red.shade300),
                          child: Center(
                            child: Text(
                              'start',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        onTap: () async {
                          startRecord();
                        },
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 48.0,
                          decoration:
                              BoxDecoration(color: Colors.blue.shade300),
                          child: Center(
                            child: Text(
                              RecordMp3.instance.status == RecordStatus.PAUSE
                                  ? 'resume'
                                  : 'pause',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        onTap: () {
                          pauseRecord();
                        },
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 48.0,
                          decoration:
                              BoxDecoration(color: Colors.green.shade300),
                          child: Center(
                            child: Text(
                              'stop',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        onTap: () {
                          stopRecord();
                          loadRecordedFiles();
                        },
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    statusText,
                    style: TextStyle(color: Colors.red, fontSize: 20),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    play();
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 30),
                    alignment: AlignmentDirectional.center,
                    width: 100,
                    height: 50,
                    child: isComplete && recordFilePath.isNotEmpty
                        ? Text(
                            "play",
                            style: TextStyle(color: Colors.red, fontSize: 20),
                          )
                        : Container(
                            child: const Text("Lets record"),
                          ),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
              initialChildSize: 1 / 3,
              minChildSize: 1 / 3, // Use minChildSize
              maxChildSize: 0.9, // Use maxChildSize
              expand: true,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: GestureDetector(
                    // onTap: _toggleSheet,
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: Colors.black,
                          tabs: <Widget>[
                            Tab(text: 'Recording'),
                            Tab(text: 'Files'),
                          ],
                        ),
                        Expanded(
                            child: TabBarView(
                          controller: _tabController,
                          children: [
                            /// Tab 1 - Recording
                            ListView.builder(
                              controller: scrollController,
                              itemCount: 50,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text('Item $index'),
                                );
                              },
                            ),
                            // Tab 2 - Files
                            ListView.builder(
                              itemCount: recordedFiles.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  // leading: Text("Leading"),
                                  title: Row(children: [
                                    Text('Recorded Audio $index', style: TextStyle(color: Colors.black),),
                                    Spacer(),
                                    ///Play Button
                                    GestureDetector(
                                        onTap: (){
                                          playSelectedFile(index);},
                                        child: Icon(Icons.play_arrow, color: Colors.green,)),
                                    Spacer(),
                                  ],),
                                  // onTap: () {
                                  //   // Play the selected file
                                  //   playSelectedFile(index);
                                  // },
                                );
                              },
                            ),
                          ],
                        ))
                      ],
                    ),
                  ),
                );
              })
        ],
      ),
    );
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      statusText = "Recording...";
      recordFilePath = await getFilePath();
      isComplete = false;
      RecordMp3.instance.start(recordFilePath, (type) {
        statusText = "Record error--->$type";
        setState(() {});
      });
    } else {
      statusText = "No microphone permission";
    }
    setState(() {});
  }

  void pauseRecord() {
    if (RecordMp3.instance.status == RecordStatus.PAUSE) {
      bool s = RecordMp3.instance.resume();
      if (s) {
        statusText = "Recording...";
        setState(() {});
      }
    } else {
      bool s = RecordMp3.instance.pause();
      if (s) {
        statusText = "Recording pause...";
        setState(() {});
      }
    }
  }

  void stopRecord() {
    bool s = RecordMp3.instance.stop();
    if (s) {
      statusText = "Record complete";
      isComplete = true;
      setState(() {});
    }
  }

  void resumeRecord() {
    bool s = RecordMp3.instance.resume();
    if (s) {
      statusText = "Recording...";
      setState(() {});
    }
  }

  late String recordFilePath;

  void play() {
    print("File path while playing is => $recordFilePath");
    try {
      if (recordFilePath.isNotEmpty && File(recordFilePath).existsSync()) {
        AudioPlayer audioPlayer = AudioPlayer();
        // audioPlayer.setVolume(1);
        // audioPlayer.setSource(DeviceFileSource(recordFilePath));

        audioPlayer.play(DeviceFileSource(recordFilePath));

        // Optional: You can listen for events like completion, errors, etc.
        audioPlayer.onPlayerComplete.listen((event) {
          print("Playback complete");
          // You can add additional logic here if needed
        });
      }
    } catch (e) {
      print("Error playing audio file=> $e");
    }
  }

  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = "${storageDirectory.path}/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }
bool playing = false;
  ///To play from scroll menu
  void playSelectedFile(int index) {
    if (index < recordedFiles.length) {
      String selectedFilePath = recordedFiles[index];
      // Add your logic to play the selected file
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(DeviceFileSource(selectedFilePath));

    }
  }

  Future<void> loadRecordedFiles() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = "${storageDirectory.path}/record";
    var directory = Directory(sdPath);
    if (directory.existsSync()) {
      List<FileSystemEntity> files = directory.listSync();
      recordedFiles = files.map((file) => file.path).toList();
      setState(() {});
    }
  }
}

///This is a Back up which is without DraggableScrollableSheet
// import 'dart:io';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:record_mp3/record_mp3.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//
//   String statusText = "";
//   bool isComplete = false;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Audio Recorder"),
//       ),
//       body: Stack(
//         children: [
//           Container(
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                   image: AssetImage("assets/BGHome.jpg"),
//                   fit: BoxFit.cover,
//                   alignment: Alignment.center,
//                   repeat: ImageRepeat.noRepeat),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: <Widget>[
//                     Expanded(
//                       child: GestureDetector(
//                         child: Container(
//                           height: 48.0,
//                           decoration: BoxDecoration(color: Colors.red.shade300),
//                           child: Center(
//                             child: Text(
//                               'start',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                         onTap: () async {
//                           startRecord();
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: GestureDetector(
//                         child: Container(
//                           height: 48.0,
//                           decoration: BoxDecoration(color: Colors.blue.shade300),
//                           child: Center(
//                             child: Text(
//                               RecordMp3.instance.status == RecordStatus.PAUSE
//                                   ? 'resume'
//                                   : 'pause',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                         onTap: () {
//                           pauseRecord();
//                         },
//                       ),
//                     ),
//                     Expanded(
//                       child: GestureDetector(
//                         child: Container(
//                           height: 48.0,
//                           decoration: BoxDecoration(color: Colors.green.shade300),
//                           child: Center(
//                             child: Text(
//                               'stop',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ),
//                         onTap: () {
//                           stopRecord();
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20.0),
//                   child: Text(
//                     statusText,
//                     style: TextStyle(color: Colors.red, fontSize: 20),
//                   ),
//                 ),
//                 GestureDetector(
//                   behavior: HitTestBehavior.opaque,
//                   onTap: () {
//                     play();
//                   },
//                   child:
//                   Container(
//                     margin: EdgeInsets.only(top: 30),
//                     alignment: AlignmentDirectional.center,
//                     width: 100,
//                     height: 50,
//                     child: isComplete && recordFilePath.isNotEmpty
//                         ? Text(
//                       "play",
//                       style: TextStyle(color: Colors.red, fontSize: 20),
//                     )
//                         : Container(child: const Text("Lets record"),),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   Future<bool> checkPermission() async {
//     if (!await Permission.microphone.isGranted) {
//       PermissionStatus status = await Permission.microphone.request();
//       if (status != PermissionStatus.granted) {
//         return false;
//       }
//     }
//     return true;
//   }
//
//   void startRecord() async {
//     bool hasPermission = await checkPermission();
//     if (hasPermission) {
//       statusText = "Recording...";
//       recordFilePath = await getFilePath();
//       isComplete = false;
//       RecordMp3.instance.start(recordFilePath, (type) {
//         statusText = "Record error--->$type";
//         setState(() {});
//       });
//     } else {
//       statusText = "No microphone permission";
//     }
//     setState(() {});
//   }
//
//   void pauseRecord() {
//     if (RecordMp3.instance.status == RecordStatus.PAUSE) {
//       bool s = RecordMp3.instance.resume();
//       if (s) {
//         statusText = "Recording...";
//         setState(() {});
//       }
//     } else {
//       bool s = RecordMp3.instance.pause();
//       if (s) {
//         statusText = "Recording pause...";
//         setState(() {});
//       }
//     }
//   }
//
//   void stopRecord() {
//     bool s = RecordMp3.instance.stop();
//     if (s) {
//       statusText = "Record complete";
//       isComplete = true;
//       setState(() {});
//     }
//   }
//
//   void resumeRecord() {
//     bool s = RecordMp3.instance.resume();
//     if (s) {
//       statusText = "Recording...";
//       setState(() {});
//     }
//   }
//
//   late String recordFilePath;
//
//   void play() {
//     print("File path while playing is => $recordFilePath");
//     try {
//       if (recordFilePath.isNotEmpty && File(recordFilePath).existsSync()) {
//         AudioPlayer audioPlayer = AudioPlayer();
//         // audioPlayer.setVolume(1);
//         // audioPlayer.setSource(DeviceFileSource(recordFilePath));
//
//         audioPlayer.play(DeviceFileSource(recordFilePath));
//
//         // Optional: You can listen for events like completion, errors, etc.
//         audioPlayer.onPlayerComplete.listen((event) {
//           print("Playback complete");
//           // You can add additional logic here if needed
//         });
//       }
//     } catch (e) {
//       print("Error playing audio file=> $e");
//     }
//   }
//
//   int i = 0;
//
//   Future<String> getFilePath() async {
//     Directory storageDirectory = await getApplicationDocumentsDirectory();
//     String sdPath = "${storageDirectory.path}/record";
//     var d = Directory(sdPath);
//     if (!d.existsSync()) {
//       d.createSync(recursive: true);
//     }
//     return "$sdPath/test_${i++}.mp3";
//   }
// }
//
