import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:seatsio/seatsio.dart';
import 'package:webview_flutter/webview_flutter.dart';

const String YourWorkspaceKey = "afcfc4d1-d11d-476d-9956-e2c4f6c5e769";
const String YourEventKey =
    "20210807-1000-eee8070a-cfd3-4cdd-9ab0-64ae38e84900";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seatsio Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Seatsio Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebViewController? _seatsioController;
  String? objectLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 456,
              child: _buildSeatsioView(),
            ),
            Text(
              objectLabel ?? 'Try to click a seat object',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadSeatsio,
        tooltip: 'Increment',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildSeatsioView() {
    return SeatsioWebView(
      enableRenderChart: false,
      onWebViewCreated: (controller) {
        print("[seatsio]->[example]-> onWebViewCreated");
        _seatsioController = controller;
        _loadSeatsio();
      },
      onObjectClicked: (object) {
        print("[seatsio]->[example]-> onObjectClicked, label: ${object.label}");
        _clickSeat(object);
      },
      onChartRendered: (chart) {
        print("[seatsio]->[example]-> onChartRendered");
        chart.requestListCategories();
      },
      onCategoryListCallback: (categoryList) {
        print(
            "[seatsio]->[example]-> onCategoryListCallback, categoryList: $categoryList");
      },
    );
  }

  void _clickSeat(SeatsioObject object) {
    setState(() {
      objectLabel = object.label;
    });
  }

  void _loadSeatsio() {
    final chartConfig = SeatingChartConfig.init().rebuild((b) => b
      ..workspaceKey = YourWorkspaceKey
      ..eventKey = YourEventKey
      ..session = "start");

    final url = _generateHtmlContent(chartConfig);
    _seatsioController?.loadUrl(url);
  }

  /// Generate html for seatsio webview
  String _generateHtmlContent(SeatingChartConfig chartConfig) {
    // Convert chart configs to map
    final chartConfigMap = chartConfig.toMap();

    // Convert map to json string
    String chartConfigJson = jsonEncode(chartConfigMap);
    chartConfigJson = '$chartConfigJson';
    // Append callback string to json string.
    final callbacks = SeatsioJsBridge.buildCallbacksConfiguration(chartConfig);
    chartConfigJson = chartConfigJson.substring(0, chartConfigJson.length - 1);
    callbacks.forEach((e) {
      chartConfigJson = "$chartConfigJson, $e";
    });
    chartConfigJson = "$chartConfigJson}";

    // Insert json string of chart config to the seatsio HTML template.
    final htmlString = seatsioHTML
        .replaceFirst("%region%", "eu")
        .replaceFirst("%configAsJs%", chartConfigJson);

    debugPrint("[Event]-> _generateHtmlContent: $htmlString");

    // Encode HTML string with utf8
    final url = Uri.dataFromString(
      htmlString,
      mimeType: "text/html",
      encoding: utf8,
    );

    return url.toString();
  }
}
