main() { var uri = Uri.tryParse('www.example.com'); print('scheme: ' + (uri?.scheme ?? '')); print('host: ' + (uri?.host ?? '')); }
