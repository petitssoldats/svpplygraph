// Generated by CoffeeScript 1.6.2
(function() {
  var GRAPH, api, async, count, fs, getDataForUser, index, offsetRequestProductForger, productRequestForger, setProduct, setUser, svpply, userName, _i;

  fs = require('fs');

  async = require('async');

  svpply = require('svpply').API;

  api = new svpply();

  count = 0;

  userName = 'Nicolas Forestier';

  userName = "Elodie P";

  GRAPH = true;

  getDataForUser = function(username) {
    return api.users.find({
      "query": userName
    }, function(data) {
      var _id;

      _id = data.response.users[0].id;
      return api.users.owns(_id, function(ownrq) {
        var n, nbrRequest, nbrWants, offset, ownsProduct, requests, _i,
          _this = this;

        ownsProduct = ownrq.response.products;
        nbrWants = data.response.users[0].products_count;
        nbrRequest = ~~(nbrWants / 100);
        requests = [];
        console.log(nbrWants, nbrRequest);
        if (nbrRequest > 0) {
          for (n = _i = 0; 0 <= nbrRequest ? _i <= nbrRequest : _i >= nbrRequest; n = 0 <= nbrRequest ? ++_i : --_i) {
            offset = n * 100;
            requests.push(offsetRequestProductForger(_id, offset));
          }
        } else {
          requests.push(offsetRequestProductForger(_id, 0));
        }
        console.log("" + requests.length + " REQUESTS");
        return async.parallel(requests, function(err, requestsResults) {
          var ownp, prod, productRequests, resreq, _j, _k, _l, _len, _len1, _len2, _len3, _m, _products, _ref, _result;

          _products = [];
          _result = [];
          for (_j = 0, _len = requestsResults.length; _j < _len; _j++) {
            resreq = requestsResults[_j];
            _ref = resreq.response.products;
            for (_k = 0, _len1 = _ref.length; _k < _len1; _k++) {
              prod = _ref[_k];
              prod.own = false;
              _products.push(prod);
            }
          }
          for (_l = 0, _len2 = ownsProduct.length; _l < _len2; _l++) {
            ownp = ownsProduct[_l];
            ownp.own = true;
            _products.push(ownp);
          }
          console.log("" + _products.length + " PRODUCTS \t/ " + ownsProduct.length + " OWNS \t / " + resreq.response.products.length + " WANTS");
          productRequests = [];
          for (_m = 0, _len3 = _products.length; _m < _len3; _m++) {
            prod = _products[_m];
            productRequests.push(productRequestForger(prod));
          }
          return async.parallel(productRequests, function(err, results) {
            var p, products, result, u, user, users, _len4, _len5, _n, _o, _ref1;

            products = [];
            users = {};
            for (_n = 0, _len4 = results.length; _n < _len4; _n++) {
              result = results[_n];
              p = setProduct(result[0]);
              products.push(p);
              _ref1 = result[1];
              for (_o = 0, _len5 = _ref1.length; _o < _len5; _o++) {
                user = _ref1[_o];
                u = setUser(user);
                if (users[u.id] == null) {
                  u.products = [p.id];
                  users[u.id] = u;
                } else {
                  users[u.id].products.push(p.id);
                }
              }
            }
            fs.writeFile('products.json', JSON.stringify(products), function(err) {
              if (err) {
                throw err;
              }
              return console.log('PRODUCTS FILE : OK');
            });
            return fs.writeFile('users.json', JSON.stringify(users), function(err) {
              if (err) {
                throw err;
              }
              return console.log('USERS FILE : OK');
            });
          });
        });
      });
    });
  };

  /* ---
  */


  offsetRequestProductForger = function(_id, offset) {
    var _this = this;

    return function(callback) {
      return api.users.wants(_id, offset, function(data) {
        return callback(null, data);
      });
    };
  };

  productRequestForger = function(product) {
    var _this = this;

    return function(callback) {
      return api.products.users(product.id, function(data) {
        var result;

        count += 1;
        result = [];
        if (data != null) {
          result = data.response.users;
          console.log("" + count + " \t | " + product.id + " \t- " + data.response.users.length + "/" + product.saves + " users");
        } else {
          console.log("" + count + " \t | " + product.id + " \t- NO DATA");
        }
        return callback(null, [product, result]);
      });
    };
  };

  setProduct = function(product, own) {
    var cat, item, _i, _len, _ref;

    item = {};
    item.id = product.id;
    item.title = product.page_title;
    item.url = product.page_url;
    item.price = [product.price, product.formatted_price];
    item.img = product.image;
    item.wants = product.saves;
    item.store = {};
    item.categories = [];
    item.own = product.own;
    item.store.id = product.store.id;
    item.store.name = product.store.name;
    _ref = product.categories;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      cat = _ref[_i];
      item.categories.push(cat.name);
    }
    return item;
  };

  setUser = function(user) {
    var item;

    item = {};
    item.id = user.id;
    item.name = user.name;
    item.username = user.username;
    item.location = user.location;
    item.url = user.url;
    item.img = user.avatar;
    item.gender = user.gender_preference;
    item.products = user.products_count;
    item.network = [user.users_following_count, user.users_followers_count];
    return item;
  };

  if (GRAPH) {
    getDataForUser(userName);
  } else {
    for (index = _i = 200; _i < 500; index = ++_i) {
      api.users.show(index, function(data) {
        var user;

        user = data.response.user;
        if (user == null) {
          return false;
        }
        if (user.products_count > 300) {
          return console.log("" + user.id + " \t| " + user.products_count + " \t | " + user.name);
        }
      });
    }
  }

  api.remaining(function(data) {
    return console.log("REMAINING " + data.response.remaining);
  });

}).call(this);
