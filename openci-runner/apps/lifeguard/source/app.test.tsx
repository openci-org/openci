import { render } from "ink-testing-library";
import { expect, test } from "vitest";
import App from "./app.js";

test("renders polling message", () => {
	const { lastFrame } = render(<App />);
	expect(lastFrame()).toBe("Polling... (Ctrl+C to exit)");
});
