import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:tfsitescape/main.dart';
import 'package:tfsitescape/services/auth.dart';
import 'package:tfsitescape/services/util.dart';
import 'package:tfsitescape/services/ui.dart';

/* Login page taking a previously initialised Auth and a void function
   which executes after authentication attempt.
   
   auth -> Auth: Needed to pass authentication after login during activities
   loginCallback -> void: Performed after authentication attempt 
*/
class LoginPage extends StatefulWidget {
  LoginPage({this.auth, this.loginCallback});

  final BaseAuth auth;
  final VoidCallback loginCallback;

  @override
  State<StatefulWidget> createState() => new LoginPageState();
}

/* State for LoginPage */
class LoginPageState extends State<LoginPage> {
  final _formKey = new GlobalKey<FormState>();

  // Empty e-mail and password starting variables
  String _email = "";
  String _password = "";

  // Used to pass the e-mail from form to password reset
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  // Used to pass focus from username to password text field
  FocusNode passwordFocus = new FocusNode();
  FocusNode confirmFocus = new FocusNode();

  // Used to check if its sign up or login happening
  bool _isLoginForm;
  // Used to check if Auth is in progress - shows loading circle
  bool _isLoading;

  // Used for displaying error/informative info below user/pass
  String _errorMessage;
  // Error color is red by default.
  Color _errorColor = Colors.red;

  @override
  void initState() {
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;

    super.initState();
  }

  Future cacheHomeImages() async {
    await precacheImage(AssetImage("images/home/hill.png"), context);
    await precacheImage(AssetImage("images/home/tower.png"), context);
    await precacheImage(AssetImage("images/home/koalas.png"), context);
    await precacheImage(AssetImage("images/home/day.png"), context);
    await precacheImage(AssetImage("images/home/weather_clear.png"), context);
    await precacheImage(AssetImage("images/home/weather_foggy.png"), context);
    await precacheImage(AssetImage("images/home/weather_rainy.png"), context);
    await precacheImage(AssetImage("images/home/weather_stormy.png"), context);
    await precacheImage(AssetImage("images/home/weather_cloudy.png"), context);
    await precacheImage(AssetImage("images/home/weather_snowy.png"), context);
    await precacheImage(AssetImage("images/home/icon_menu.png"), context);
    await precacheImage(AssetImage("images/home/icon_help.png"), context);
    await precacheImage(AssetImage("images/home/divider.png"), context);
    await precacheImage(AssetImage("images/home/icon_scanner.png"), context);
    await precacheImage(
        AssetImage("images/home/icon_calculations.png"), context);
    await precacheImage(AssetImage("images/home/icon_reports.png"), context);

    return;
  }

  /* Check if form is valid before perform login or signup */
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      resetForm();
      return true;
    }
    return false;
  }

  /* Perform login or signup */
  void validateAndSubmit() async {
    // Remove any informatives as "Password is required" could show below.
    showInformative("");
    // Show the loading circle while Auth in progress.
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    // Check if successful and return result.
    if (validateAndSave()) {
      String userId = "";
      FirebaseUser user;
      try {
        if (_isLoginForm) {
          user = await widget.auth.signIn(_email, _password);
          if (user != null && !user.isEmailVerified) {
            setState(
              () async {
                showInformative(
                    "E-mail verification required. Please check your e-mail address for a verification e-mail to continue.");
                widget.auth.signOut();
              },
            );
          } else {
            userId = user.uid;
            await refreshSites();
          }
          print('Signed in: $userId');
        } else {
          userId = await widget.auth.signUp(_email, _password);
          widget.auth.sendEmailVerification();
          showInformative(
              "A verification e-mail has been sent to your e-mail address.");
          print('Signed up user: $userId');
          setState(
            () {
              _formKey.currentState.reset();
              _isLoginForm = false;
            },
          );
        }
        // Perform the callback void function.
        if (userId.length > 0 &&
            userId != null &&
            _isLoginForm &&
            user.isEmailVerified) {
          await cacheHomeImages();
          widget.loginCallback();
        }
      } on PlatformException catch (e) {
        print('Error: $e');

        String firebaseError = e.toString();

        setState(
          () {
            _isLoading = false;
            // This is so ugly
            if (firebaseError.contains("ERROR_EMAIL_ALREADY_IN_USE")) {
              _errorMessage = "   This e-mail address is  already registered.";
            } else if (firebaseError.contains("TOO_MANY_REQUESTS") ||
                firebaseError.contains("ERROR_NETWORK_REQUEST_FAILED")) {
              _errorMessage = "   Error communicating with service.";
            } else if (firebaseError.contains("ERROR_INVALID_EMAIL")) {
              _errorMessage = "   Invalid e-mail format.";
            } else
              _errorMessage = "   Invalid e-mail or password.";
          },
        );
        _formKey.currentState.reset();
      }
    }
    /* Remove loading circle at the end of Auth attempt. */
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
  }

  /* Behavior for showSecondaryButton() on press to toggle */
  void toggleFormMode() {
    resetForm();
    setState(
      () {
        _isLoginForm = !_isLoginForm;
      },
    );
  }

  /* Removes user/pass if entry is wrong for fresh start. */
  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
    passwordController.clear();
    confirmController.clear();
  }

  /* Shows blue text below entry fields if text is not empty or null 
  
     text -> String: Message to show after state is set
  */
  void showInformative(String text) {
    if (text == "") {
      setState(() {
        _errorMessage = "";
        _errorColor = Colors.red;
      });
    } else {
      setState(() {
        _errorMessage = text;
        _errorColor = Colors.blue;
      });
    }
  }

  // Build the widget.
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          ),
          showBottomArt(),
          _showLogo(),
          _showTitle(),
          _showFooter(),
          // _showCircularProgress(),
        ],
      ),
    );
  }

  Widget _showLogo() {
    return Container(
      margin: EdgeInsets.only(top: ScreenUtil().setHeight(220)),
      decoration: BoxDecoration(
        image: DecorationImage(
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
          image: AssetImage('images/login/logo.png'),
        ),
      ),
    );
  }

  /* Title above fields */
  Widget _showTitle() {
    return Container(
      margin: EdgeInsets.only(
          left: 16, right: 16, top: ScreenUtil().setHeight(320)),
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              "sitescape",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontFamily: "Quicksand",
                fontSize: 1000.0,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              "H A N D O V E R  T O O L  P A C K",
              style: TextStyle(
                color: Colors.white,
                fontFamily: "Quicksand",
                fontWeight: FontWeight.w200,
                fontSize: ScreenUtil().setSp(54),
              ),
            ),
          ),
          _showForm(),
        ],
      ),
    );
  }

  /* Overall widget structure passed in build. */
  Widget _showForm() {
    return new Container(
      padding: EdgeInsets.fromLTRB(24.0, 0, 24.0, 0),
      child: new Center(
        child: Form(
          key: _formKey,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(height: ScreenUtil().setHeight(50)),
                      showEmailInput(),
                      showPasswordInput(),
                      showConfirmPassword(),
                      showErrorMessage(_errorColor),
                      SizedBox(height: ScreenUtil().setHeight(30)),
                      showForgotPassword(),
                    ]),
              ),
              showPrimaryButton(),
              showSecondaryButton(),
            ],
          ),
        ),
      ),
    );
  }

  /* Logo above user/pass */
  Widget _showFooter() {
    return Container(
      margin: EdgeInsets.only(bottom: ScreenUtil().setHeight(50)),
      alignment: Alignment.bottomCenter,
      child: new Text(
        gVersion,
        style: TextStyle(
          color: Colors.white,
          fontSize: ScreenUtil().setSp(28),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }

  /* E-mail, on field submit will pass focus to pass */
  Widget showEmailInput() {
    return new Container(
      child: TextFormField(
        controller: emailController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          prefixIcon: IconButton(
            icon: ImageIcon(
              AssetImage("images/icons/icon_email.png"),
              size: ScreenUtil().setSp(36),
              color: Colors.white,
            ),
          ),
          hintText: 'E-mail',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: ScreenUtil().setSp(42),
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: ScreenUtil().setSp(36),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2.0),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        style: TextStyle(
          color: Colors.white,
          fontSize: ScreenUtil().setSp(42),
        ),
        // Must be valid entry
        validator: (value) => value.isEmpty ? 'E-mail required.' : null,
        // Used to pass focus from user -> pass
        onFieldSubmitted: (String value) {
          FocusScope.of(context).requestFocus(passwordFocus);
        },
        onTap: () {
          // Reset error message
          showInformative("");
        },
        onSaved: (value) => {_email = value.trim()},
      ),
    );
  }

  /* Password, obscured input */
  Widget showPasswordInput() {
    return Container(
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        // This is near identical to user function.
        child: TextFormField(
          focusNode: passwordFocus,
          controller: passwordController,
          textCapitalization: TextCapitalization.none,
          autofocus: false,
          cursorColor: Colors.white,
          obscureText: true,
          decoration: InputDecoration(
            fillColor: Colors.indigo[400].withOpacity(0.8),
            prefixIcon: IconButton(
              icon: ImageIcon(
                AssetImage("images/icons/icon_password.png"),
                size: ScreenUtil().setSp(42),
                color: Colors.white,
              ),
            ),
            hintText: 'Password',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: ScreenUtil().setSp(42),
            ),
            errorStyle: TextStyle(
              color: Colors.red,
              fontSize: ScreenUtil().setSp(36),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white, width: 2.0),
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[400]),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red),
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: ScreenUtil().setSp(42),
          ),
          // Must be valid entry
          validator: (value) => value.isEmpty || (value.length < 5)
              ? 'Password must be longer.'
              : null,
          onSaved: (value) => _password = value.trim(),
          onTap: () {
            // Reset error message
            showInformative("");
          },
          onFieldSubmitted: (String _password) => {
            _isLoginForm
                ? validateAndSubmit()
                : FocusScope.of(context).requestFocus(confirmFocus)
          },
        ),
      ),
    );
  }

  /* Identical to two top, may need refactoring, only shows on registration */
  Widget showConfirmPassword() {
    return !_isLoginForm
        ? Container(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
              // This is near identical to user function.
              child: TextFormField(
                focusNode: confirmFocus,
                controller: confirmController,
                textCapitalization: TextCapitalization.none,
                autofocus: false,
                cursorColor: Colors.white,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: ImageIcon(
                      AssetImage("images/icons/icon_confirm_password.png"),
                      size: ScreenUtil().setSp(42),
                      color: Colors.white,
                    ),
                  ),
                  hintText: 'Confirm Password',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: ScreenUtil().setSp(42),
                  ),
                  errorStyle: TextStyle(
                    color: Colors.red,
                    fontSize: ScreenUtil().setSp(36),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2.0),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]),
                  ),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenUtil().setSp(42),
                ),
                // Must be valid entry
                validator: (value) => (value.isEmpty || (value.length < 5)) ||
                        (value != passwordController.text)
                    ? 'Password must be valid and same as above.'
                    : null,
                onTap: () {
                  // Reset error message
                  showInformative("");
                },
                onFieldSubmitted: (String _confirm) => validateAndSubmit(),
              ),
            ),
          )
        : new Container();
  }

  /* Progress circle which shows on primary button on press during Auth. */
  Widget showCircularProgress() {
    if (_isLoading) {
      return Container(
        margin: EdgeInsets.all(12.0),
        child: Center(
          child: FittedBox(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  /* Error message below user/pass, color depends on informative/error */
  Widget showErrorMessage(Color color) {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return Container(
        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
        child: Text(
          _errorMessage,
          style: TextStyle(
            fontSize: ScreenUtil().setSp(36),
            color: color,
            height: 1.0,
          ),
        ),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  /* Shows below user/pass, on tap will send reset pass e-mail */
  Widget showForgotPassword() {
    if (_isLoginForm) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: InkWell(
          onTap: () {
            widget.auth.sendPasswordResetEmail(
              emailController.text.trim(),
            );
            showInformative("   Password reset e-mail requested.");
          },
          child: Text(
            "Forgot your password?",
            style: TextStyle(
              color: Colors.indigoAccent[100],
              fontSize: ScreenUtil().setSp(42),
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  /* Used to perform login or startup depending on which mode in toggle form */
  Widget showPrimaryButton() {
    return new Container(
      padding: EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
      child: SizedBox(
        height: ScreenUtil().setSp(48) * 3,
        child: new RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(0.0),
          ),
          color: Color.fromRGBO(86, 189, 162, 1.0),
          child: !_isLoading
              ? new Text(
                  _isLoginForm ? 'Login' : 'Create account',
                  style: new TextStyle(
                    fontFamily: "Quicksand",
                    fontSize: ScreenUtil().setSp(48),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                )
              : showCircularProgress(),
          onPressed: validateAndSubmit,
        ),
      ),
    );
  }

  /* Used to swap between login/signup */
  Widget showSecondaryButton() {
    return new Container(
      padding: EdgeInsets.fromLTRB(36.0, 10, 36.0, 0.0),
      child: SizedBox(
        height: ScreenUtil().setSp(48) * 2.5,
        child: new RaisedButton(
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(0.0),
          ),
          color: Colors.white,
          child: new Text(
            _isLoginForm ? 'I don\'t have an account' : 'Return to login',
            style: new TextStyle(
                fontFamily: "Quicksand",
                fontSize: ScreenUtil().setSp(42),
                color: Color.fromRGBO(86, 189, 162, 1.0),
                fontWeight: FontWeight.w500),
          ),
          onPressed: toggleFormMode,
        ),
      ),
    );
  }
}
