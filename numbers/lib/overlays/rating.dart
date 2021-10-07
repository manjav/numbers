import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:numbers/utils/analytics.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'all.dart';

class RateOverlay extends StatefulWidget {
  static Future<bool> showRating(BuildContext context) async {
    // Pref.rate.set(0);
    // Pref.ratedBefore.set(0);
    // Pref.rateTarget.set(5);
    print(
        "Rating rate: ${Pref.rate.value}, playCount: ${Pref.playCount.value}, rateTarget: ${Pref.rateTarget.value}");
    // Send to store
    if (Pref.rate.value == 5) {
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
        const url =
            'https://play.google.com/store/apps/details?id=game.block.puzzle.drop.the.number.merge';
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      }
      return true;
    }

    // Repeat rating request
    if (Pref.rate.value >= 5 || Pref.playCount.value < Pref.rateTarget.value)
      return false; // Already 5 rating or pending to reach target play count
    int rating = 0;
    try {
      rating = await Rout.push(context, RateOverlay());
    } catch (e) {
      return false;
    }
    Pref.rate.set(rating);
    Pref.rateTarget.increase(10);

    String comment = "";
    if (rating > 0) {
      if (rating < 5) comment = await Rout.push(context, ReviewDialog());
      await Rout.push(
          context,
          Overlays.message(
              context,
              Center(
                  child: Text("Thanks a lot.",
                      style: Theme.of(context).textTheme.headline5))),
          barrierDismissible: true);
    }
    Analytics.log('rate', <String, dynamic>{
      'numRuns': Pref.visitCount.value,
      'rating': rating,
      'comment': comment
    });
    print("Rating rate: ${Pref.rate.value} rating: $rating comment: $comment");
    return true;
  }

  final initialRating;
  RateOverlay({this.initialRating = 1});
  @override
  _RateOverlayState createState() => _RateOverlayState();
}

class _RateOverlayState extends State<RateOverlay> {
  int _response = 0;
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return WillPopScope(
        onWillPop: () async => false,
        child: Overlays.basic(context, "rating",
            height: 280.d,
            hasClose: false,
            title: "Rate Us",
            padding: EdgeInsets.fromLTRB(22.d, 18.d, 22.d, 22.d),
            content: Stack(alignment: Alignment.topRight, children: <Widget>[
              Text(
                  "If you injoy playing, please take a moment to rate it.\n\nThanks for your support!",
                  textAlign: TextAlign.justify,
                  style: theme.textTheme.headline6),
              Center(
                  child: RatingBar.builder(
                      initialRating: widget.initialRating.toDouble(),
                      itemSize: 36.d,
                      minRating: 1.0,
                      allowHalfRating: false,
                      glowColor: Colors.amber,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 3.0),
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
                      errorMessage: Center(
                          child: Text("First rate us !",
                              style: theme.textTheme.headline5)),
                      isEnable: _response > 0,
                      colors: TColors.blue.value,
                      content: Center(
                          child:
                              Text("Rate", style: theme.textTheme.headline5)),
                      onTap: () => Navigator.pop(context, _response)))
            ])));
  }
}

class ReviewDialog extends StatefulWidget {
  @override
  State<ReviewDialog> createState() => ReviewDialogState();
}

class ReviewDialogState extends State<ReviewDialog> {
  final _commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
        body: Overlays.basic(context, "review",
            height: 0,
            width: 320.d,
            title: "Review",
            closeOnBack: false,
            padding: EdgeInsets.all(16.d),
            content: Column(
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
                      decoration: InputDecoration(
                          hintText: "Tell us your comments...")),
                  const SizedBox(height: 15),
                  BumpedButton(
                      errorMessage: Center(
                          child: Text("Insert your comment !",
                              style: theme.textTheme.headline5)),
                      isEnable: _commentController.text != "",
                      colors: TColors.green.value,
                      content: Center(
                          child:
                              Text("Send", style: theme.textTheme.headline5)),
                      onTap: () =>
                          Navigator.pop(context, _commentController.text))
                ])));
  }
}
