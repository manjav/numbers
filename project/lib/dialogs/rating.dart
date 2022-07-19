import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';
import 'package:project/dialogs/dialogs.dart';
import 'package:project/dialogs/toast.dart';
import 'package:project/theme/themes.dart';
import 'package:project/utils/analytic.dart';
import 'package:project/utils/localization.dart';
import 'package:project/utils/prefs.dart';
import 'package:project/utils/utils.dart';
import 'package:project/widgets/buttons.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RatingDialog extends AbstractDialog {
  final int initialRating;
  RatingDialog({Key? key, this.initialRating = 1})
      : super(
          DialogMode.rating,
          key: key,
          height: 280.d,
          showCloseButton: false,
          title: "rate_title".l(),
          padding: EdgeInsets.fromLTRB(22.d, 18.d, 22.d, 22.d),
        );
  @override
  createState() => _RatingDialogState();
}

class _RatingDialogState extends AbstractDialogState<RatingDialog> {
  var _response = 0;
  var _hours = 0;

  @override
  void initState() {
    _hours = DateTime.now().hoursSinceEpoch;
    debugPrint(
        "Rate => ${Pref.rate.value}, The last rating time elapsed:${_hours - Pref.rateLastTime.value}");

    // Repeat rating request
    // Already 5 rating or pending to proper time
    if (Pref.rate.value >= 5 || (_hours - Pref.rateLastTime.value) < 24) {
      Navigator.pop(context, _response = -1);
      return;
    }
    // Bad rating and pending to proper time
    if (Pref.rate.value > 0 && (_hours - Pref.rateLastTime.value) < 24 * 3) {
      Navigator.pop(context, _response = -1);
      return;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return super.build(context);
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Stack(alignment: Alignment.topRight, children: <Widget>[
          Text("rate_message".l(),
              textAlign: TextAlign.justify, style: theme.textTheme.headline6),
          Center(
              child: RatingBar.builder(
                  initialRating: widget.initialRating.toDouble(),
                  itemSize: 36.d,
                  minRating: 1.0,
                  allowHalfRating: false,
                  glowColor: Colors.amber,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 3.0),
                  onRatingUpdate: (rating) {
                    _response = rating.toInt();
                    setState(() {});
                  },
                  itemBuilder: (context, _) => Icon(Icons.star,
                      color: Colors.amber[_response == 0 ? 800 : 500]))),
          Positioned(
              bottom: 12.d,
              right: 48.d,
              left: 48.d,
              child: BumpedButton(
                  errorMessage: Toast("rate_error".l()),
                  isEnable: _response > 0,
                  colors: TColors.blue.value,
                  content: Center(
                      child:
                          Text("rate_l".l(), style: theme.textTheme.headline5)),
                  onTap: _onSubmit))
        ]));
  }

  _onSubmit() async {
    Pref.rate.set(_response);
    Pref.rateLastTime.set(_hours);

    String comment = "";
    if (_response > 0) {
      if (_response < 5) {
        var r = await Rout.push(context, ReviewDialog());
        if (r != null) {
          comment = r;
          var url =
              "https://numbers.sarand.net/review/?rate=$_response&comment=$comment&visits=${Pref.visitCount.value}";
          var response = await http.get(Uri.parse(url));
          if (response.statusCode != 200) debugPrint('Failure status code 😱');
        }
      } else {
        await _requestReview();
      }
      if (!mounted) return;
      await Rout.push(context, Toast("thanks_l".l()), barrierDismissible: true);
    }
    Analytics.design('rate', parameters: <String, dynamic>{
      'rating': _response,
      'visits': Pref.visitCount.value,
      'comment': comment
    });
    debugPrint(
        "Rating rate: ${Pref.rate.value} rating: $_response comment: $comment");
  }

  // Send to store
  static Future<bool> _requestReview() async {
    if (Pref.rate.value != 5) return false;
    Pref.rate.set(6);
    // if (Configs.instance.buildConfig!.target == "cafebazaar") {
    //   if (Platform.isAndroid) {
    //     AndroidIntent intent = AndroidIntent(
    //         data: 'bazaar://details?id=com.gerantech.muslim.holy.quran',
    //         action: 'android.intent.action.EDIT',
    //         package: 'com.farsitel.bazaar');
    //     await intent.launch();
    //   }
    //   return;
    // }

    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      if (Pref.ratedBefore.value == 0) {
        inAppReview.requestReview();
        Pref.ratedBefore.set(1);
        return true;
      }
      inAppReview.openStoreListing();
    } else {
      var url = "app_url".l();
      await canLaunchUrlString(url)
          ? await launchUrlString(url)
          : throw 'Could not launch $url';
    }
    return true;
  }
}

class ReviewDialog extends AbstractDialog {
  ReviewDialog({Key? key})
      : super(
          DialogMode.review,
          key: key,
          height: 0,
          width: 320.d,
          title: "review_l".l(),
          closeOnBack: false,
          padding: EdgeInsets.all(16.d),
        );
  @override
  createState() => _ReviewDialogState();
}

class _ReviewDialogState extends AbstractDialogState<ReviewDialog> {
  final _commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget contentFactory(ThemeData theme) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
              autofocus: true,
              controller: _commentController,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
              style: theme.textTheme.headline6,
              decoration: InputDecoration(hintText: "review_hint".l())),
          const SizedBox(height: 15),
          BumpedButton(
              errorMessage: Toast("review_error".l()),
              isEnable: _commentController.text != "",
              colors: TColors.green.value,
              content: Center(
                  child: Text("send_l".l(), style: theme.textTheme.headline5)),
              onTap: () => Navigator.pop(context, _commentController.text))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: super.build(context)));
  }
}
