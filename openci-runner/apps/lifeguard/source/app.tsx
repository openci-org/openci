import { Text } from "ink";
import { useEffect } from "react";

export default function App() {
	useEffect(() => {
		const interval = setInterval(() => {
			console.log("Polling...");
		}, 1000);

		return () => clearInterval(interval);
	}, []);

	return <Text>Polling... (Ctrl+C to exit)</Text>;
}
