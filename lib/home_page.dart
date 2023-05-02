import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final scrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  List gifs = [];
  int offset = 0;
  bool isLoading = false;
  bool showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      _scrollListener();
      setState(() {
        if (scrollController.offset >= 400) {
          showBackToTopButton = true; // show the back-to-top button
        } else {
          showBackToTopButton = false; // hide the back-to-top button
        }
      });
    });
    fetchGifs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("GIPHY API"),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                onChanged: (value) => {
                  Future.delayed(const Duration(milliseconds: 3000), () {
                    offset = 0;
                    fetchGifs();
                    scrollController.animateTo(
                      0.0,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 300),
                    );
                  }),
                },
                decoration: const InputDecoration(
                    prefixIcon: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: Icon(
                        Icons.search,
                      ),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    hintText: "e.g. Cat laughing"),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                    controller: scrollController,
                    itemCount: isLoading ? gifs.length + 1 : gifs.length,
                    itemBuilder: (context, index) {
                      if (index < gifs.length) {
                        final gif = gifs[index];
                        final gifUrl = gif['images']['fixed_height']['url'];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            gifUrl,
                            height: 300,
                            fit: BoxFit.fitWidth,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    }),
              ),
            ],
          ),
        ),
        floatingActionButton: !showBackToTopButton
            ? (null)
            : (FloatingActionButton(
                child: const Icon(Icons.arrow_upward),
                onPressed: () {
                  setState(() {
                    scrollController.animateTo(
                      scrollController.position.minScrollExtent,
                      curve: Curves.easeOut,
                      duration: const Duration(milliseconds: 300),
                    );
                  });
                },
              )));
  }

  Future<void> fetchGifs() async {
    const apiKey = ""; //your api key
    if (apiKey.isEmpty) {
      searchController.text = "No api key was found!";
      return print("No api key was found!");
    }

    String url;
    if (searchController.text.isEmpty) {
      url =
          'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=10&offset=$offset';
    } else {
      String search = searchController.text;
      url =
          'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=$search&limit=10&offset=$offset';
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body)["data"] as List;
      if (offset != 0) {
        setState(() {
          gifs = gifs + json;
        });
      } else {
        setState(() {
          gifs = json;
        });
      }
    } else {
      searchController.text = "Something went wrong!";
      return print("Something went wrong!");
    }
  }

  Future<void> _scrollListener() async {
    if (scrollController.position.pixels ==
            scrollController.position.maxScrollExtent &&
        !isLoading) {
      setState(() {
        isLoading = true;
      });
      offset += 10;
      await fetchGifs();
      setState(() {
        isLoading = false;
      });
    }
  }
}
