import React, { useEffect, useState } from 'react'
import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';

// Firebase
import { initializeApp } from 'firebase/app';
import { getFirestore, doc, getDoc } from 'firebase/firestore'

const firebaseConfig = {
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const tmp_sensor_1 = doc(db, 'tempreture/sensor1');

async function get_doc_data(firestore_doc) {
	const snapshot = await getDoc(firestore_doc);
	return snapshot
}

const TempRenderer = ({ temperature }) => {
	if (temperature == undefined) {
		return (
			<></>
		)
	}
	const temperature_json = JSON.parse(temperature[0])
	const t = new Date(temperature_json.timestamp)
	const formatted = t.toISOString();

	return (
		<View>
			<Text style={{color: "white"}}>Temperature: {temperature_json.value}</Text>
			<Text style={{color: "white"}}>Measured: {formatted}</Text>
		</View>
	) 

}

// App
const App = () => {
	const [tmpData, setTempData] = useState(undefined)
	
	useEffect(() => {
		async function get_temp_data() {
		get_doc_data(tmp_sensor_1).then(res => {
			setTempData(res.data().values)
			// console.log(JSON.parse(res.data().values[0]))
		})
		}
		get_temp_data()
	})

	return (
		<View style={styles.container}>
			<StatusBar style="light" />
			<Text style={{color: "white", fontSize: 22}}>BlubBlub</Text>
			<TempRenderer temperature={tmpData} />
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
