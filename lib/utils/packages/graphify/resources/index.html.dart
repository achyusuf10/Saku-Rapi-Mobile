// ignore_for_file: leading_newlines_in_multiline_strings

import 'package:app_saku_rapi/utils/packages/graphify/controller/js_methods.dart';

String indexHtml({
  required String id,
  String? dependencies,
  bool isDarkMode = false,
}) {
  return '''<!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:opsz,wght@6..12,400;6..12,500;6..12,600;6..12,700;6..12,800;6..12,900&display=swap" rel="stylesheet">
      <style>
        * {
          font-family: 'Nunito Sans', sans-serif !important;
        }
        html, body {
          background-color: transparent;
          height: -webkit-fill-available;
          box-sizing: content-box;
          margin: 0;
          overflow: hidden;
          width: 100%;
          height: 100%;
        }
        #chart { height: -webkit-fill-available; }
      </style>
    </head>
    <body>
      <div id="chart"></div>
      ${dependencies ?? ''}
      <script>
          const dom = document.getElementById('chart');
          const context = (window.parent && window.parent.window) || window || {};
          const chart = context.echarts.init(dom, ${isDarkMode ? "'dark'" : "'light'"}, { renderer: 'canvas', useDirtyRect: false });
          context.${JsMethods.initChart}('$id', chart, {});
          context.${JsMethods.updateChart}('$id', {});
          window.addEventListener('resize', chart.resize);
      </script>
    </body>
    </html>
''';
}
