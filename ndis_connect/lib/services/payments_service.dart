import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentsService {
  PaymentsService(String publishableKey) {
    Stripe.publishableKey = publishableKey;
  }

  // Backend should create PaymentIntent and return clientSecret.
  Future<void> startSubscriptionCheckout(Uri backendCreateIntentEndpoint) async {
    final res = await http.post(backendCreateIntentEndpoint);
    if (res.statusCode != 200) throw Exception('Stripe error ${res.statusCode}:${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final clientSecret = data['clientSecret'] as String;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'NDIS Connect',
      ),
    );

    await Stripe.instance.presentPaymentSheet();
  }
}

