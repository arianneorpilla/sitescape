import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfsitescapeweb/main.dart';

import 'package:tfsitescapeweb/services/auth.dart';
import 'package:tfsitescapeweb/services/util.dart';

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

  bool lazyAuth(String userId) {
    return (userId == "EeIVhpj0tPgjZTpJh3TULdqKrcG3" ||
        userId == "dHJnsajX75PnZ0oShFg3B2CaZMq1");
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
            // await refreshSites();
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
          sites = await fetchSites();
          isAdmin = lazyAuth(userId);
          widget.loginCallback();
        }
        // else if (!lazyAuth(userId)) {
        //   setState(() {
        //     _errorMessage = "   Elevated permissions are required to use " +
        //         "the Sitescape web console.";
        //   });
        // }
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
              _errorMessage = "   Error communicating with server.";
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
          Center(
            child: Container(
              width: 600,
              height: 650,
              // decoration: BoxDecoration(
              //   border: Border.all(
              //     color: Colors.white,
              //     width: 1,
              //   ),
              // ),
              padding: EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.25),
              child: _showForm(),
            ),
          )
          // _showCircularProgress(),
        ],
      ),
    );
  }

  /* Overall widget structure passed in build. */
  Widget _showForm() {
    return new Container(
      padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
      child: new Center(
        child: Form(
          key: _formKey,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              showTitle(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              Container(
                child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      showEmailInput(),
                      showPasswordInput(),
                      showConfirmPassword(),
                      showErrorMessage(_errorColor),
                      // showForgotPassword(),
                    ]),
              ),
              showPrimaryButton(),
              // showSecondaryButton(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              showFooter(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  /* Logo above user/pass */
  Widget showFooter() {
    return Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // new Text(
          //   "P O W E R E D  B Y",
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 12,
          //     fontWeight: FontWeight.w300,
          //   ),
          //   textAlign: TextAlign.justify,
          // ),
          // new Text(
          //   "T O W E R F O R C E",
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 20,
          //     fontWeight: FontWeight.w300,
          //   ),
          // ),
          new Text(""),
          // new Text(
          //   versionAndBuild,
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 9,
          //     fontWeight: FontWeight.w500,
          //   ),
          //   textAlign: TextAlign.justify,
          // ),
        ],
      ),
    );
  }

  /* Title above fields */
  Widget showTitle() {
    return Container(
      child: new FittedBox(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              new Text(
                "sitescape",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontFamily: "Quicksand",
                ),
              ),
              new Text(
                "W E B  C O N S O L E",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 3,
                  fontWeight: FontWeight.w300,
                  fontFamily: "Quicksand",
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
          fit: BoxFit.contain),
    );
  }

  /* E-mail, on field submit will pass focus to pass */
  Widget showEmailInput() {
    return Container(
      child: TextFormField(
        controller: emailController,
        textCapitalization: TextCapitalization.none,
        autofocus: false,
        keyboardType: TextInputType.emailAddress,
        cursorColor: Colors.white,
        obscureText: false,
        decoration: InputDecoration(
          fillColor: Colors.indigo[400].withOpacity(0.8),
          filled: true,
          prefixIcon: Icon(
            Icons.mail,
            color: Colors.white,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.red,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.white,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey[600],
            ),
          ),
          hintText: 'E-mail',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          errorStyle: TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16),
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
            filled: true,
            prefixIcon: Icon(
              Icons.vpn_key,
              color: Colors.white,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              borderSide: BorderSide(
                width: 1,
                color: Colors.grey,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              borderSide: BorderSide(
                width: 1,
                color: Colors.red,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              borderSide: BorderSide(
                width: 1,
                color: Colors.white,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              borderSide: BorderSide(
                width: 1,
                color: Colors.grey[600],
              ),
            ),
            hintText: 'Password',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            errorStyle: TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
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
          // onFieldSubmitted: (String _password) => {
          //   _isLoginForm
          //       ? validateAndSubmit()
          //       : FocusScope.of(context).requestFocus(confirmFocus)
          // },
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
                  fillColor: Colors.indigo[400].withOpacity(0.8),
                  filled: true,
                  prefixIcon: Icon(
                    Icons.check_box,
                    color: Colors.white,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: Colors.grey,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: Colors.red,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: Colors.white,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(5),
                    ),
                    borderSide: BorderSide(
                      width: 1,
                      color: Colors.grey[600],
                    ),
                  ),
                  hintText: 'Confirm Password',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  errorStyle: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
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
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
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
            fontSize: 14.0,
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
        padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
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
              fontSize: 16,
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
        height: 60.0,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: _isLoginForm
              ? Colors.green[400].withOpacity(0.9)
              : Colors.indigoAccent[400].withOpacity(0.9),
          child: !_isLoading
              ? new Text(
                  _isLoginForm ? 'Login' : 'Create account',
                  style: new TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
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
      padding: EdgeInsets.fromLTRB(0.0, 10, 0.0, 0.0),
      child: SizedBox(
        height: 40.0,
        child: new RaisedButton(
          elevation: 20,
          shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(20.0),
          ),
          color: _isLoginForm
              ? Colors.indigoAccent[400].withOpacity(0.9)
              : Colors.red[300].withOpacity(0.9),
          child: new Text(
            _isLoginForm ? 'I don\'t have an account' : 'Return to login',
            style: new TextStyle(
                fontSize: 16.0,
                color: Colors.white,
                fontWeight: FontWeight.w500),
          ),
          onPressed: toggleFormMode,
        ),
      ),
    );
  }
}
