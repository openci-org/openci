import { describe, it, expect } from "vitest";
import { emailLayout } from "../templates/base-layout";

describe("emailLayout", () => {
  it("includes development banner when isDevelopment is true", () => {
    const html = emailLayout({
      title: "Test",
      body: "<p>Hello</p>",
      isDevelopment: true,
    });
    expect(html).toContain("development environment");
    expect(html).toContain("background-color:#fbbf24");
  });

  it("excludes development banner when isDevelopment is false", () => {
    const html = emailLayout({
      title: "Test",
      body: "<p>Hello</p>",
      isDevelopment: false,
    });
    expect(html).not.toContain("development environment");
    expect(html).not.toContain("#fbbf24");
  });

  it("excludes development banner when isDevelopment is undefined", () => {
    const html = emailLayout({
      title: "Test",
      body: "<p>Hello</p>",
    });
    expect(html).not.toContain("development environment");
  });

  it("escapes HTML in title", () => {
    const html = emailLayout({
      title: '<script>alert("xss")</script>',
      body: "<p>Body</p>",
    });
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
  });

  it("contains the body content", () => {
    const html = emailLayout({
      title: "Test",
      body: "<p>Custom content here</p>",
    });
    expect(html).toContain("<p>Custom content here</p>");
  });

  it("returns valid HTML structure", () => {
    const html = emailLayout({
      title: "Test",
      body: "<p>Body</p>",
    });
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("<html");
    expect(html).toContain("</html>");
    expect(html).toContain("OpenCI");
  });
});
