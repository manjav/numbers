import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:numbers/dialogs/dialogs.dart';
import 'package:numbers/dialogs/toast.dart';
import 'package:numbers/utils/ads.dart';
import 'package:numbers/utils/analytic.dart';
import 'package:numbers/utils/localization.dart';
import 'package:numbers/utils/prefs.dart';
import 'package:numbers/utils/themes.dart';
import 'package:numbers/utils/utils.dart';
import 'package:numbers/widgets/buttons.dart';
import 'package:numbers/widgets/components.dart';

// ignore: must_be_immutable
class ShopDialog extends AbstractDialog {
  ShopDialog()
      : super(DialogMode.shop,
            title: "shop_l".l(),
            padding: EdgeInsets.all(8.d),
            width: 310.d,
            height: 410.d,
            statsButton: SizedBox(),
            scoreButton: SizedBox());
  @override
  _ShopDialogState createState() => _ShopDialogState();
}

class _ShopDialogState extends AbstractDialogState<ShopDialog> {
  String _message = "wait_l".l();
  var coins = Map<String, ProductDetails>();
  var others = Map<String, ProductDetails>();
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    _initShop();
    super.initState();
  }

  Future<void> _initShop() async {
    var available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      setState(() => _message = "shop_unavailable");
      return;
    }
    if (coins.length > 0) {
      setState(() => _message = "");
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () => _subscription.cancel(), onError: (error) => print(error));

    Set<String> skus = {"no_ads"};
    for (var i = 0; i < 6; i++) skus.add("coin_$i");
    var response = await InAppPurchase.instance.queryProductDetails(skus);
    coins = Map<String, ProductDetails>();
    others = Map<String, ProductDetails>();
    for (var product in response.productDetails) {
      if (product.isConsumable)
        coins[product.id] = product;
      else
        others[product.id] = product;
    }
    setState(() => _message = "");
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          setState(() => _message = "");
          // _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          setState(() => _message = "");
          _deliverProduct(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var items = coins.values.toList();
    widget.coinButton = Positioned(
        top: 32.d,
        left: 12.d,
        child: Components.coins(context, "shop", clickable: false));
    widget.child = Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
            height: 200.d,
            child: GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 3,
              crossAxisSpacing: 3.d,
              mainAxisSpacing: 2.d,
              childAspectRatio: 1,
              children: List.generate(
                  items.length, (i) => _itemBuilder(theme, items[i])),
            )),
        Container(
            height: 72.d,
            padding: EdgeInsets.fromLTRB(10.d, 6.d, 10.d, 12.d),
            decoration: ButtonDecor(TColors.whiteFlat.value, 12.d, true, false),
            child: Row(children: [
              SizedBox(width: 8.d),
              SVG.show("noads", 48),
              SizedBox(width: 24.d),
              Expanded(
                  child:
                      Text("shop_noads".l(), style: theme.textTheme.bodyText2)),
              SizedBox(
                  width: 92.d,
                  height: 40.d,
                  child: BumpedButton(
                    cornerRadius: 8.d,
                    colors: TColors.green.value,
                    content: Center(
                        child: Text(
                            "${others.length > 0 ? others["no_ads"]!.price : 0}",
                            style: theme.textTheme.headline5)),
                    onTap: () => _onShopItemTap(others["no_ads"]!),
                  )),
              SizedBox(height: 4.d)
            ])),
        Container(
            height: 32.d,
            alignment: Alignment.center,
            child: Container(
                width: 48.d,
                height: 7.d,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(24.d))))),
        Container(
            height: 80.d,
            padding: EdgeInsets.symmetric(horizontal: 8.d),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                      width: 124.d,
                      child: BumpedButton(
                          cornerRadius: 16.d,
                          isEnable: Ads.isReady(),
                          colors: TColors.orange.value,
                          errorMessage:
                              Toast("ads_unavailable".l(), monoIcon: "0"),
                          onTap: _freeCoin,
                          content: Row(children: [
                            SVG.icon("0", theme),
                            SizedBox(width: 8.d),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("free_l".l(),
                                    style: theme.textTheme.headline5),
                                Row(
                                  children: [
                                    SVG.show("coin", 24.d),
                                    Text("+100",
                                        style: theme.textTheme.headline6)
                                  ],
                                )
                              ],
                            )
                          ]))),
                  SizedBox(
                      width: 140.d,
                      child: BumpedButton(
                          onTap: _restorePurchases,
                          colors: TColors.green.value,
                          cornerRadius: 16.d,
                          content: Row(children: [
                            SVG.icon("5", theme),
                            SizedBox(width: 12.d),
                            Text("shop_restore".l(),
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headline6)
                          ])))
                ]))
      ]),
      _overlay(theme)
    ]);

    return super.build(context);
  }

  ProductDetails? _findProduct(String id) {
    if (coins.containsKey(id)) return coins[id];
    if (others.containsKey(id)) return others[id];
    return null;
  }

  _overlay(ThemeData theme) {
    if (_message == "") return SizedBox();
    return Container(
        color: TColors.black.value[0].withAlpha(230),
        alignment: Alignment.center,
        padding: EdgeInsets.all(16.d),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_message, style: theme.textTheme.headline4),
          SizedBox(height: 32.d),
          _message == "wait_l".l()
              ? CircularProgressIndicator()
              : TextButton(
                  onPressed: () {
                    if (_message == "shop_unavailable".l())
                      Navigator.of(context).pop();
                    else
                      setState(() => _message = "");
                  },
                  child: Text("OK"))
        ]));
  }

  Widget _itemBuilder(ThemeData theme, ProductDetails product) {
    return Container(
        height: 110.d,
        child: BumpedButton(
          colors: TColors.whiteFlat.value,
          onTap: () => _onShopItemTap(product),
          content: Column(children: [
            SizedBox(height: 7.d),
            Row(children: [
              SVG.show("coin", 20.d),
              Text(" ${product.name}", style: theme.textTheme.subtitle1)
            ]),
            SizedBox(height: 7.d),
            Container(
              width: 92.d,
              height: 40.d,
              decoration: ButtonDecor(TColors.green.value, 8.d, true, false),
              child: Padding(
                  padding: EdgeInsets.fromLTRB(6.d, 6.d, 6.d, 7.d),
                  child: Text("${product.price}",
                      style: theme.textTheme.headline6,
                      textAlign: TextAlign.center)),
            ),
            SizedBox(height: 4.d)
          ]),
        ));
  }

  _onShopItemTap(ProductDetails product) {
    setState(() => _message = "wait_l".l());
    var purchaseParam = PurchaseParam(productDetails: product);
    if (product.isConsumable) {
      InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
    } else {
      InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  _restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
    setState(() {});
  }

  _freeCoin() async {
    var reward = await Ads.showRewarded();
    if (reward != null) {
      Pref.coin.increase(100, itemType: "shop", itemId: "ad");
      setState(() {});
    }
  }

  _deliverProduct(PurchaseDetails purchaseDetails) {
    var p = _findProduct(purchaseDetails.productID);
    var type = "no_ads";
    if (purchaseDetails.productID == "no_ads") {
      Pref.noAds.set(1);
    } else {
      type = "coin";
      Pref.coin.increase(p!.amount,
          itemType: "shop", itemId: purchaseDetails.productID);
    }

    Analytics.purchase(p!.currencyCode, p.rawPrice, p.id, type,
        purchaseDetails.purchaseID!, purchaseDetails.verificationData.source);
  }
}

extension PExt on ProductDetails {
  String get name => title.split(' ')[0];
  int get amount => int.parse(name);
  bool get isConsumable => id.substring(0, 5) == "coin_";
}
