import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/db/databse_helper.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart';
import '../../constants/constants.dart';
import '../home.dart';
import '../main_screen.dart';
import 'app_text_field.dart';
import 'package:http/http.dart' as http;

class AuthActionButton extends StatefulWidget {
  AuthActionButton(
      {Key? key,
      required this.onPressed,
      required this.isLogin,
      required this.isAbsenmasuk,
      required this.isAbsendinasluar,
      required this.isAbsenkeluar,
      required this.reload});
  final Function onPressed;
  final bool isLogin;
  final bool isAbsenmasuk;
  final bool isAbsendinasluar;
  final bool isAbsenkeluar;
  final Function reload;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  PersistentBottomSheetController? _bottomSheetController;
  final MLService _mlService = locator<MLService>();
  final CameraService _cameraService = locator<CameraService>();
  final TextEditingController _nipTextEditingController =
      TextEditingController(text: '');

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');
  String selectedRole = 'Pilih Role'; // Default role selection
  User? predictedUser;

  Future _signUp(context) async {
    DatabaseHelper _databaseHelper = DatabaseHelper.instance;
    List predictedData = _mlService.predictedData;
    String nip = _nipTextEditingController.text;

    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;
    User userToSave = User(
      nip: nip,
      user: user,
      password: password,
      modelData: predictedData,
    );
    await _databaseHelper.insert(userToSave);

    // Menghapus data prediksi dalam layanan ML
    this._mlService.setPredictedData([]);

    // Navigasi ke MyHomePage setelah sign-up berhasil
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
    );

    // Mengirim data ke server setelah menghapus data prediksi
    await _sendDataToServer(nip, user, password, selectedRole, predictedData,
        _cameraService.imagePath);
  }

  Future<void> _sendDataToServer(String nip, String user, String password,
      String selectedRole, List predictedData, String? imagePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(Constants.BASEURL + Constants.REGISTER),
    );

    request.fields['nip'] = nip;
    request.fields['user'] = user;
    request.fields['password'] = password;
    request.fields['role'] = selectedRole;
    request.fields['modelData'] = predictedData.toString();
    request.files.add(
      await http.MultipartFile.fromPath(
        'user_image',
        imagePath!,
      ),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      // File berhasil diunggah
      // Tambahkan logika atau tindakan yang diperlukan setelah pengunggahan file
      print('File uploaded successfully');
      print('Data berhasil dikirim ke server.');
    } else {
      // Gagal mengunggah file
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(
                'Failed to upload file. Status Code: ${response.statusCode}'),
          );
        },
      );
    }

    // var url = Uri.parse(Constants.BASEURL + Constants.REGISTER);

    // var response = await http.post(url, body: {
    //   'nip': nip,
    //   'user': user,
    //   'password': password,
    //   'modelData': predictedData.toString(),
    // });
    // print('modelData:' + predictedData.toString());
    // if (response.statusCode == 200) {
    //   print('Data berhasil dikirim ke server.');
    // } else {
    //   print(
    //       'Gagal mengirim data ke server. Kode status: ${response.statusCode}');
    //   // Tampilkan pesan atau lakukan tindakan kesalahan sesuai kebutuhan
    // }
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    if (this.predictedUser!.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => MainScreen(
                    imagePath: this.predictedUser!.user,
                    username: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Password Salah!'),
          );
        },
      );
    }
  }

  Future _presensiIn(context) async {
    String password = _passwordTextEditingController.text;
    if (this.predictedUser!.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => MainScreen(
                    imagePath: this.predictedUser!.user,
                    username: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Password masuk Salah!'),
          );
        },
      );
    }
  }

  Future _presensiDinasluar(context) async {
    String password = _passwordTextEditingController.text;
    if (this.predictedUser!.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => MainScreen(
                    imagePath: this.predictedUser!.user,
                    username: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Password masuk Salah!'),
          );
        },
      );
    }
  }

  Future _presensiAuth(context) async {
    String password = _passwordTextEditingController.text;
    if (this.predictedUser!.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => MainScreen(
                    imagePath: this.predictedUser!.user,
                    username: _cameraService.imagePath!,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Password masuk Salah!'),
          );
        },
      );
    }
  }

  Future<User?> _predictUser() async {
    User? userAndPass = await _mlService.predict();
    return userAndPass;
  }

  Future onTap() async {
    try {
      bool faceDetected = await widget.onPressed();
      if (faceDetected) {
        if (widget.isLogin) {
          var user = await _predictUser();
          if (user != null) {
            this.predictedUser = user;
          }
        } else if (widget.isAbsenmasuk) {
          var user = await _predictUser();
          if (user != null) {
            this.predictedUser = user;
          }
        } else if (widget.isAbsenkeluar) {
          var user = await _predictUser();
          if (user != null) {
            this.predictedUser = user;
          }
        } else if (widget.isAbsendinasluar) {
          var user = await _predictUser();
          if (user != null) {
            this.predictedUser = user;
          }
        }
        signSheet(context);
        // bottomSheetController.closed.whenComplete(() => widget.reload());
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.green,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CAPTURE',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }

  signSheet(BuildContext context) {
    _bottomSheetController = showBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.green, // Warna latar belakang hijau
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      widget.isLogin && predictedUser != null
                          ? Container(
                              child: Text(
                                'Selamat Datang, ' + predictedUser!.user + '.',
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : widget.isLogin
                              ? Container(
                                  child: Text(
                                  'User Tidak Ditemukan',
                                  style: TextStyle(fontSize: 20),
                                ))
                              : Container(),
                      widget.isAbsenmasuk && predictedUser != null
                          ? Container(
                              child: Text(
                                'Selamat Datang Abesen Masuk, ' +
                                    predictedUser!.user +
                                    '.',
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : widget.isAbsenmasuk
                              ? Container(
                                  child: Text(
                                  'User Tidak ABSESN MASUK Ditemukan ',
                                  style: TextStyle(fontSize: 20),
                                ))
                              : Container(),
                      widget.isAbsenkeluar && predictedUser != null
                          ? Container(
                              child: Text(
                                'Selamat Datang Abesen keluar, ' +
                                    predictedUser!.user +
                                    '.',
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : widget.isAbsenkeluar
                              ? Container(
                                  child: Text(
                                  'User Tidak ABSESN keluar Ditemukan ',
                                  style: TextStyle(fontSize: 20),
                                ))
                              : Container(),
                      widget.isAbsendinasluar && predictedUser != null
                          ? Container(
                              child: Text(
                                'Selamat Datang Abesen Dinas Luar, ' +
                                    predictedUser!.user +
                                    '.',
                                style: TextStyle(fontSize: 20),
                              ),
                            )
                          : widget.isAbsendinasluar
                              ? Container(
                                  child: Text(
                                  'User Tidak ABSESN MASUK Ditemukan ',
                                  style: TextStyle(fontSize: 20),
                                ))
                              : Container(),
                      Container(
                        child: Column(
                          children: [
                            !widget.isLogin
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black),
                                          children: [
                                            TextSpan(
                                                text: 'PNS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black)),
                                            TextSpan(
                                                text: ' gunakan ',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            TextSpan(
                                                text: 'NIP',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black)),
                                            TextSpan(text: ', '),
                                            TextSpan(
                                                text: 'Non PNS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors
                                                        .yellow.shade800)),
                                            TextSpan(
                                                text: ' gunakan ',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            TextSpan(
                                                text: 'NIKU',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors
                                                        .yellow.shade800)),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              8), // Jarak antara teks di atas dan AppTextField
                                      AppTextField(
                                        controller: _nipTextEditingController,
                                        labelText: "Masukkan NIP/NIKU",
                                      ),
                                    ],
                                  )
                                : Container(),
                            SizedBox(height: 10),
                            DropdownButton<String>(
                              value: selectedRole,
                              dropdownColor: Colors.green,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedRole = newValue!;
                                });
                              },
                              items: <String>[
                                'Pilih Role',
                                'Dosen',
                                'Item 3'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 10),
                            !widget.isLogin
                                ? AppTextField(
                                    controller: _userTextEditingController,
                                    labelText: "Nama Lengkap",
                                  )
                                : Container(),
                            SizedBox(height: 10),
                            widget.isLogin && predictedUser == null
                                ? Container()
                                : AppTextField(
                                    controller: _passwordTextEditingController,
                                    labelText: "Password",
                                    isPassword: true,
                                  ),
                            SizedBox(height: 10),
                            SizedBox(height: 10),
                            widget.isLogin && predictedUser != null
                                ? AppButton(
                                    text: 'LOGIN',
                                    onPressed: () async {
                                      _signIn(context);
                                    },
                                    icon: Icon(
                                      Icons.login,
                                      color: Colors.white,
                                    ),
                                  )
                                : widget.isAbsenmasuk
                                    ? AppButton(
                                        text: 'ABESN MASUK WIDGET',
                                        onPressed: () async {
                                          await _presensiIn(context);
                                        },
                                        icon: Icon(
                                          Icons.person_add,
                                          color: Colors.white,
                                        ),
                                      )
                                    : widget.isAbsendinasluar
                                        ? AppButton(
                                            text: 'ABESN MASUK WIDGET',
                                            onPressed: () async {
                                              await _presensiDinasluar(context);
                                            },
                                            icon: Icon(
                                              Icons.person_add,
                                              color: Colors.white,
                                            ),
                                          )
                                        : widget.isAbsenkeluar
                                            ? AppButton(
                                                text: 'ABESN keluar WIDGET',
                                                onPressed: () async {
                                                  await _presensiAuth(context);
                                                },
                                                icon: Icon(
                                                  Icons.person_add,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : !widget.isLogin
                                                ? AppButton(
                                                    color: Colors.grey.shade600,
                                                    text: 'SIGN UP',
                                                    onPressed: () async {
                                                      if (selectedRole ==
                                                          'Pilih Role') {
                                                        // Menampilkan alert jika pengguna tidak memilih role
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              title: Text(
                                                                  'Peringatan'),
                                                              content: Text(
                                                                  'Silakan pilih role terlebih dahulu.'),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(
                                                                      'OK'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                        return; // Hentikan eksekusi selanjutnya jika role tidak dipilih
                                                      } else {
                                                        await _signUp(context);
                                                      }
                                                    },
                                                    icon: Icon(
                                                      Icons.person_add,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Container(),
                          ],
                        ),
                      ),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     _bottomSheetController?.close();
                      //   },
                      //   child: Text('Close Bottom Sheet'),
                      // ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
