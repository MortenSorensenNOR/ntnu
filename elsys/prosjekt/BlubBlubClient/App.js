import React, { useEffect, useState } from 'react'
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';

import TemperatureClient from './src/components/temperatureClient';
import VideoClient from './src/components/videoClient';

const piURL = "172.20.10.5";

const App = () => {
	return (
		<View style={styles.container}>
			<StatusBar style="light" />
			<Text style={{color: "white", fontSize: 32}}>BlubBlubClient 🫧🐟</Text>
			<TemperatureClient style={{ flex: 1 }} />
			<VideoClient url={"http://" + String(piURL) +":8081"} />
			<VideoClient url={"http://" + String(piURL) +":8082"} />
		</View>
	)
}

const styles = StyleSheet.create({
container: {
	flex: 1,
	backgroundColor: '#1C1B1D',
	alignItems: 'center',
	justifyContent: 'center',
},
});

export default App