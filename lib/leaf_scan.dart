// // ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, non_constant_identifier_names
import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:agro_x/encyclopedia_screen.dart';
import 'package:agro_x/home_screen.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_info_screen.dart';

class LeafScan extends StatefulWidget {
  final String modelName;
  //parameters passed from home screen
  const LeafScan({super.key, required this.modelName});

  @override
  // ignore: no_logic_in_create_state
  State<LeafScan> createState() => _LeafScanState(modelName);
}

class _LeafScanState extends State<LeafScan> {
  String modelName;
  _LeafScanState(this.modelName);

  // To indicate when the model is loading or processing an image
  bool isLoading = false;
  bool _isInferenceRunning = false;

  File? pickedImage;
  bool isButtonPressedCamera = false;
  bool isButtonPressedGallery = false;
  Color backgroundColor = const Color(0xffe9edf1);
  Color secondaryColor = const Color(0xffe1e6ec);
  Color accentColor = const Color(0xff2d5765);

  List? results;
  String confidence = "";
  String name = "";
  String cropName = "";
  String diseaseName = "";
  String diseaseUrl = "";
  bool resultVisibility = false;

  String modelPathSelector() {
    switch (widget.modelName.toLowerCase()) {
      case "apple":
        return 'assets/models/Apple';
      case "bellpepper":
        return 'assets/models/BellPepper';
      case "cherry":
        return 'assets/models/Cherry';
      case "corn":
        return 'assets/models/Corn';
      case "grape":
        return 'assets/models/Grape';
      case "peach":
        return 'assets/models/Peach';
      case "potato":
        return 'assets/models/Potato';
      case "rice":
        return 'assets/models/Rice';
      case "tomato":
        return 'assets/models/Tomato';
      default:
        return "";
    }
  }

  @override
  void initState() {
    super.initState();
    // print(modelName);
    loadModel().then((_) {
      setState(() {});
    });
  }

  Future<void> loadModel() async {
    setState(() {
      // Indicate that image picking is in progress
      isLoading = true;
    });
    String modelPath = modelPathSelector();
    // print(modelPath);
    await Tflite.loadModel(
        model: "$modelPath/model_unquant.tflite",
        labels: "$modelPath/labels.txt");

    setState(() {
      isLoading = false;
    });

    // print("Result after loading model: $resultant");
  }

  Future<void> getImage(ImageSource source) async {
    setState(() {
      // Indicate that image picking is in progress
      isLoading = true;
    });
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image != null) {
        final imageTemporary = File(image.path);
        setState(() {
          pickedImage = imageTemporary;
          applyModelOnImage(pickedImage!);
          resultVisibility = true;
          isButtonPressedCamera = false;
          isButtonPressedGallery = false;
        });
        applyModelOnImage(pickedImage!);
      }
    } on PlatformException catch (e) {
      print("Failed to pick image: $e");
    } finally {
      setState(() => isLoading = false); // Reset loading indicator
    }
  }

  applyModelOnImage(File file) async {
    if (_isInferenceRunning) {
      print('Model inference is already in progress.');
      return;
    }

    setState(() {
      _isInferenceRunning = true;
    });

    try {
      var res = await Tflite.runModelOnImage(
        path: file.path,
        numResults: 2,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

      if (res != null && res.isNotEmpty) {
        setState(() {
          results = res;
          confidence =
              "${((res[0]["confidence"] as double) * 100.0).toStringAsFixed(2)}%";
          name = res[0]["label"];
          splitModelResult(name);
        });
      }
    } catch (e) {
      print("Error running model inference: $e");
    } finally {
      setState(() {
        _isInferenceRunning = false;
      });
    }
  }

  void splitModelResult(String fullName) {
    List temp = fullName.split(' ');
    cropName = temp[0];
    temp.removeAt(0);
    diseaseName = temp.join(' ');
    // print(crop_name);
    // print(disease_name);
  }

  void buttonPressedCamera() {
    setState(() {
      isButtonPressedCamera = !isButtonPressedCamera;
      getImage(ImageSource.camera);
    });
  }

  void buttonPressedGallery() {
    setState(() {
      isButtonPressedGallery = !isButtonPressedGallery;
      getImage(ImageSource.gallery);
    });
  }

  void closeModel() async {
    await Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: backgroundColor,
      systemNavigationBarColor: secondaryColor,
    ));

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: CurvedNavigationBar(
        onTap: (index) {
          //todo implement transition to other screens
          // print(index);
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Encyclopedia(),
              ),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AppInfoScreen(),
              ),
            );
          }
        },
        index: 1,
        backgroundColor: backgroundColor,
        color: secondaryColor,
        buttonBackgroundColor: backgroundColor,
        animationDuration: const Duration(
          milliseconds: 300,
        ),
        items: [
          NeumorphicIcon(
            Icons.menu_book_rounded,
            style: NeumorphicStyle(
              color: accentColor,
              intensity: 20,
            ),
          ),
          NeumorphicIcon(
            Icons.home_rounded,
            style: NeumorphicStyle(
              color: accentColor,
              intensity: 20,
            ),
          ),
          NeumorphicIcon(
            Icons.info_rounded,
            style: NeumorphicStyle(
              color: accentColor,
              intensity: 20,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Lottie.asset(
                    'assets/39771-farm.json',
                    width: 150,
                    height: 150,
                  ),
                ),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: LinearProgressIndicator(
                    color: accentColor,
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/app_icon.svg',
                              width: 30,
                              height: 30,
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: const Text(
                                "Agro-X",
                                style: TextStyle(
                                  fontFamily: 'odibeeSans',
                                  fontSize: 25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: SvgPicture.asset(
                          'assets/tensorflow-icontext.svg',
                          width: 40,
                          height: 40,
                        ),
                      )
                    ],
                  ),
                  Center(
                    child: Neumorphic(
                      style: NeumorphicStyle(
                        border: NeumorphicBorder(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: pickedImage != null
                            ? Image.file(
                                pickedImage!,
                                width: 300,
                                height: 300,
                                fit: BoxFit.cover,
                              )
                            : LottieBuilder.asset(
                                'assets/39771-farm.json',
                                width: 300,
                                height: 300,
                              ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        NeumorphicButton(
                          tooltip: 'Camera',
                          style: const NeumorphicStyle(
                            color: Color(0xffe9edf1),
                            intensity: 10,
                          ),
                          pressed: isButtonPressedCamera,
                          onPressed: buttonPressedCamera,
                          child: Column(
                            children: [
                              Icon(
                                Icons.camera_rounded,
                                size: 40,
                                color: accentColor,
                              ),
                              const Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                        NeumorphicButton(
                          tooltip: 'Gallery',
                          style: const NeumorphicStyle(
                            color: Color(0xffe9edf1),
                            intensity: 10,
                          ),
                          pressed: isButtonPressedGallery,
                          onPressed: buttonPressedGallery,
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 40,
                                color: accentColor,
                              ),
                              const Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: !resultVisibility,
                    child: Flexible(
                      child: Neumorphic(
                        style: NeumorphicStyle(
                          // color: backgroundColor,
                          // color: Colors.red.shade700,
                          lightSource: LightSource.topLeft,
                          intensity: 20,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(10)),
                        ),
                        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 20, 10, 10),
                              child: Row(
                                children: [
                                  NeumorphicIcon(
                                    Icons.camera_alt_rounded,
                                    style: NeumorphicStyle(
                                      color: accentColor,
                                      intensity: 20,
                                    ),
                                    size: 15,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(
                                      left: 5,
                                    ),
                                    child: const Text(
                                      "Select an image of the plant's leaf to view the results",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Row(
                                children: [
                                  NeumorphicIcon(
                                    Icons.light_mode_rounded,
                                    style: NeumorphicStyle(
                                      color: accentColor,
                                      intensity: 20,
                                    ),
                                    size: 15,
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(
                                      left: 5,
                                    ),
                                    child: const Text(
                                      'The image must be well lit and clear',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  NeumorphicIcon(
                                    Icons.hide_image_rounded,
                                    style: NeumorphicStyle(
                                      color: accentColor,
                                      intensity: 20,
                                    ),
                                    size: 15,
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          5, 0, 10, 0),
                                      child: const Text(
                                        "Images other than the specific plant's leaves may lead to inaccurate results",
                                        softWrap: true,
                                        maxLines: 10,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                        // textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: resultVisibility,
                    child: Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          String searchQuery;
                          if (diseaseName.toLowerCase() != "healthy") {
                            searchQuery =
                                "$modelName+$diseaseName".replaceAll(' ', '+');
                            // diseaseUrl = "https://www.google.com/search?q=" +
                            //     modelName +
                            //     '+' +
                            //     diseaseName.replaceAll(' ', '+');
                            // Uri url = Uri.parse(diseaseUrl);
                            // await launchUrl(url, mode: LaunchMode.inAppWebView);
                          } else {
                            searchQuery = "$modelName+plant+care+tips";
                            // diseaseUrl = "https://www.google.com/search?q=" +
                            //     modelName +
                            //     '+' +
                            //     'plant+care+tips';
                            // Parse the url and launch it in the inAppWebView
                            // Uri url = Uri.parse(diseaseUrl);
                            // await launchUrl(url, mode: LaunchMode.inAppWebView);
                          }

                          // Encode the search query to ensure that the url is valid
                          String encodedSearchQuery =
                              Uri.encodeFull(searchQuery);

                          // construct the full url
                          String diseaseUrl =
                              "https://www.google.com/search?q=$encodedSearchQuery";
                          print("Launching URL: $diseaseUrl");

                          // Parse the url and launch it in the inAppWebView
                          Uri url = Uri.parse(diseaseUrl);

                          launchUrl(url, mode: LaunchMode.inAppWebView);
                          // if (await canLaunchUrl(url)) {
                          //   await launchUrl(url, mode: LaunchMode.inAppWebView);
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(
                          //       backgroundColor: accentColor,
                          //       content:
                          //           Text('Could not launch URL: $diseaseUrl'),
                          //     ),
                          //   );
                          print('Could not launch $diseaseUrl');
                          // }
                        },
                        child: Neumorphic(
                          style: NeumorphicStyle(
                            // color: backgroundColor,
                            // color: Colors.red.shade700,
                            lightSource: LightSource.topLeft,
                            intensity: 20,
                            boxShape: NeumorphicBoxShape.roundRect(
                                BorderRadius.circular(10)),
                          ),
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        50, 10, 50, 20),
                                    child: NeumorphicText(
                                      diseaseName,
                                      style: const NeumorphicStyle(
                                        color: Colors.black,
                                        // color: Colors.green.shade800,
                                        intensity: 20,
                                      ),
                                      textStyle: NeumorphicTextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Confidence : $confidence',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                    Row(
                                      children: [
                                        NeumorphicIcon(
                                          Icons.info_rounded,
                                          style: NeumorphicStyle(
                                            color: accentColor,
                                            intensity: 20,
                                          ),
                                          size: 15,
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 5,
                                          ),
                                          child: Text(
                                            diseaseName.toLowerCase() !=
                                                    "healthy"
                                                ? 'Tap on this card to read more about this disease'
                                                : 'Tap on this card for $modelName plant care tips',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    closeModel();
  }
}
