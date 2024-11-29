import React, { useEffect, useState } from 'react'
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Dimensions } from 'react-native';
import { LineChart } from 'react-native-chart-kit';

// Firebase
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc, onSnapshot } from 'firebase/firestore';

const firebaseConfig = {
    apiKey: "AIzaSyAeYsU_L8iFSLoLEvZClcqXzo1KR5Ng5tI",
    authDomain: "elsysgkgruppe15.firebaseapp.com",
    projectId: "elsysgkgruppe15",
    storageBucket: "elsysgkgruppe15.appspot.com",
    messagingSenderId: "634176965179",
    appId: "1:634176965179:web:b9242c8e8038501b9e6a1e",
    measurementId: "G-K3YRMXSZNL"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const tmp_sensor_1 = doc(db, 'tempreture/sensor1');

async function get_doc_data(firestore_doc) {
	const snapshot = await getDoc(firestore_doc);
	return snapshot;
}

const convertUnixToTime = (unix) => {
	const months = ["januar", "februar", "mars", "april", "mai", "juni", "juli", "august", "september", "oktober", "november", "desember"];

	const t = new Date(unix);
	const date = t.getDate();
	const month = months[t.getMonth()];
	const year = t.getFullYear();
	const hour = t.getHours();
	const minute = t.getMinutes();
	const second = t.getSeconds();
	// return `${date}. ${month} ${year} : ${hour}:${minute}:${second}`;
	return `${minute}`;
}

const TemperatureRenderer = ({ temperature }) => {
	if (temperature == undefined) {
		return (
			<></>
		);
	}

	let tmpData = [];
	let lables = [];
	for (let i = 0; i < temperature.length; i++) {
		const data = JSON.parse(temperature[i]);
		const tmp = data.value;
		const time = data.timestamp;
		tmpData.push(tmp);
		lables.push(convertUnixToTime(time))
	}

	if (tmpData.length < 1 || lables.length < 1) {
		return (<></>)
	}

	return (
		<View style={{ width: Dimensions.get("window").width * 0.85}}>
			<LineChart 
				data={{
					labels: lables,
					datasets: [{ data: tmpData }]
				}}
				width={Dimensions.get("window").width * 0.85}
				height={200}
				yAxisSuffix="C°"
				yAxisInterval={1} // optional, defaults to 1
				chartConfig={{
					backgroundColor: "#e26a00",
					backgroundGradientFrom: "#fb8c00",
					backgroundGradientTo: "#ffa726",
					decimalPlaces: 1, // optional, defaults to 2dp
					color: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
					labelColor: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
					style: {
					  borderRadius: 8,
					  padding: 18
					},
					propsForDots: {
					  r: "6",
					  strokeWidth: "2",
					  stroke: "#ffa726"
					}
				  }}
				  bezier
				  fromZero
				  style={{
					marginVertical: 12,
					borderRadius: 12
				  }}
			/>
		</View>
	);
}

const TemperatureClient = (props) => {
	const [tmpData, setTempData] = useState(null)

	async function get_temp_data() {
		const res = await get_doc_data(tmp_sensor_1);
		setTempData(res.data().values);
	}

	useEffect(() => {
		get_temp_data()
	}, [])

	useEffect(() => {
		const unsubscribe = onSnapshot(tmp_sensor_1, (snapshot) => {
			if (snapshot.exists()) {
				const data = snapshot.data().values;
				setTempData(data);
			} else {
				setTempData(null);
			}
		})
		return () => {
			unsubscribe();
		}
	}, [])
	
	if (tmpData == null) {
		return <Text>Loading...</Text>
	}

	return (
		<TemperatureRenderer temperature={tmpData} />
	);
}

export default TemperatureClient;