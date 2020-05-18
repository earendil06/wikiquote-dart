// TODO: Put public facing types in this file.
import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class Wikiquote {
  String _baseUrl(String lang) => 'http://${lang}.wikiquote.org/w/api.php';

  String _searchUrl(String lang, String search) =>
      _baseUrl(lang) +
      '?format=json&action=query&list=search&continue=&srsearch=${search}';

  String _pageUrl(String lang, String p) =>
      _baseUrl(lang) +
      '?format=json&action=parse&prop=text|categories&" "disableeditsection&page=${p}';

  String _mainPageUrl(String lang, String main) =>
      _baseUrl(lang) + '?format=json&action=parse&prop=text&page=${main}';

  String _randomUrl(String lang, int limit) =>
      _baseUrl(lang) + '?format=json&action=query&list=random&rnnamespace=0&rnlimit=${limit}';

  List<String> supportedLanguages() {
    return ['en'];
  }

  Future<Quote> quoteOfTheDay(String lang) async {
    var url = _mainPageUrl(lang, 'Main Page');
    var future = await http.get(url);
    var body = json.decode(future.body);
    var parsed = (body['parse'] ?? const {});
    var text = (parsed['text'] ?? const {});
    var star = (text['*'] ?? '');
    var html = [for(var e in parse(star).getElementById('mf-qotd')
        .querySelectorAll('table table table tr td')) e.text.replaceAll('~', '').replaceAll('\n', '')];

    return Quote()..quote = html[0]..author = html[1];
  }

  Future<List<String>> search(String article, String lang) async {
    var url = _searchUrl(lang, article);
    var response = await http.get(url);
    var body = (json.decode(response.body) ?? const {});
    var query = (body['query'] ?? const {});
    var search = (query['search'] ?? []);
    var content = [for (var e in search) e['title']?.toString() ?? ''];
    return content;
  }

  Future<List<Quote>> quotes(String result, String lang, int maxQuotes) async {
    var url = _pageUrl(lang, result);
    var future = await http.get(url);
    var body = json.decode(future.body);
    var parsed = (body['parse'] ?? const {});
    var text = (parsed['text'] ?? const {});
    var star = (text['*'] ?? '');
    var res = [];
    parse(star)
    .querySelectorAll('ul li')
    .forEach((element) {
      var author = element.querySelector('ul li');
      if(author != null && author.classes.isEmpty) {
        res.add(Quote()..quote = element.text.replaceAll(author.text, '')..author = author.text);
      }
    });
    return res;
  }

  Future<List<String>> randomTitles(String lang, int maxTitles) async {
    var url = _randomUrl(lang, maxTitles);
    var response = await http.get(url);
    var body = (json.decode(response.body) ?? const {});
    var query = (body['query'] ?? const {});
    var search = (query['random'] ?? []);
    var content = [for (var e in search) e['title']?.toString() ?? ''];
    return content;
  }
}

class Quote {
  String author;
  String quote;
}
