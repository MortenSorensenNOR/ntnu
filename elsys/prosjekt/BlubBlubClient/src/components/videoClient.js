import React, { useEffect, useState } from 'react';
import { View, Text, Dimensions } from 'react-native';
import { WebView } from 'react-native-webview';

const windowWidth = Dimensions.get("window").width;
const windowHeight = Dimensions.get("window").height;

const VideoClient = (props) => {
    return (
        <View style={{ height: 250 }}>
            <WebView 
                originWhitelist={['*']}
                source={{ html: `<img style="border-radius: 32px;" width="100%" height="96%" src="${props.url}" />` }} 
                style={{ flex: 1, width: windowWidth * 0.85, borderRadius: 8, backgroundColor: 'transparent' }} 
            />
        </View>
    );
}

export default VideoClient