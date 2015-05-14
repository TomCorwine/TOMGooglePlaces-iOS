# TOMGooglePlaces-iOS
Simple SDK for address autocompletion using Google Places API.

### Usage
[TOMGooglePlace placesFromString:location:completionBlock:]

*string* is the partial string that user has typed in.

*location* is a CLLocation object to help Google narrow down results - can be nil.

*completionBlock* a block that will be called upon receiving results.

The result will be an array of TOMGooglePlace's. Properties of this class are basically what Google returns in the API.

### Notes

In order to avoid dependencies, this library doesn't do any kind of validation of the returned JSON. It's just a quick thing I wrote to accomplish a simple task. Feel free to enhance and submit a pull request.

See my [TOMJSONAdapter-iOS](https://github.com/TomCorwine/TOMJSONAdapter-iOS "TOMJSONAdapter-iOS") project for a simple way to validate returned JSON results.
