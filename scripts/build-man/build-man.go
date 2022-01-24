package main

import (
	"fmt"
	nhtml "golang.org/x/net/html"
	"golang.org/x/net/html/atom"
	"html"
	"os"
	"strings"
	"unicode"
)

func main() {
	doc, err := nhtml.Parse(os.Stdin)
	if err != nil {
		die(err)
	}

	for doc = doc.FirstChild; doc != nil; doc = doc.NextSibling {
		handleNode(doc)
	}
}

func createLink(href string) *nhtml.Node {
	return &nhtml.Node{
		Type:      nhtml.ElementNode,
		DataAtom:  atom.Link,
		Data:      "link",
		Namespace: "",
		Attr: []nhtml.Attribute{
			{
				Key: "rel",
				Val: "stylesheet",
			},
			{
				Key: "href",
				Val: href,
			},
		},
	}
}

func formatId(id string) string {
	b := strings.Builder{}
	for _, c := range id {
		if c == '_' {
			b.WriteByte('-')
		} else {
			b.WriteRune(unicode.ToLower(c))
		}
	}
	return b.String()
}

func inClass(n *nhtml.Node, m string) bool {
	for _, a := range n.Attr {
		if a.Key == "class" {
			for _, c := range strings.Split(a.Val, " ") {
				if c == m {
					return true
				}
			}
		}
	}

	return false
}

func findOsNode(n *nhtml.Node) *nhtml.Node {
	for ; n != nil; n = n.NextSibling {
		if n.DataAtom == atom.Td {
			if inClass(n, "foot-os") {
				return n
			}
		}
	}

	return nil
}

func handleNode(n *nhtml.Node) {
	switch n.Type {
	case nhtml.TextNode:
		fmt.Print(html.EscapeString(html.UnescapeString(n.Data)))
	case nhtml.ElementNode:
		switch n.DataAtom {
		case atom.Style:
			return
		case atom.Head:
			n.AppendChild(createLink("/style.css"))
			n.AppendChild(createLink("/man.css"))
		case atom.Dt:
			if n.FirstChild.DataAtom == atom.A {
				n.FirstChild.FirstChild.NextSibling = n.FirstChild.NextSibling
				n.FirstChild = n.FirstChild.FirstChild
			}
		case atom.H1:
			n.Data = "h2"
			txt := n.FirstChild.FirstChild.Data
			n.FirstChild.Attr[0].Val = "anchor"
			n.FirstChild.FirstChild.Data = "§"
			n.AppendChild(&nhtml.Node{
				Type: nhtml.TextNode,
				Data: txt,
			})
		case atom.Div:
			if inClass(n, "Bd") && n.FirstChild.DataAtom == atom.Code {
				fc := n.FirstChild
				fc.FirstChild.Data = strings.ReplaceAll(fc.FirstChild.Data, "\n ", "")
				n.FirstChild = &nhtml.Node{
					FirstChild: fc,
					Type:       nhtml.ElementNode,
					DataAtom:   atom.Pre,
					Data:       "pre",
				}
				fc.Parent = n.FirstChild
			}
		case atom.Span:
			if inClass(n, "Pa") {
				n.Data = "kbd"
			}
		case atom.Tr:
			os := findOsNode(n.FirstChild)
			if os == nil {
				break
			}

			n.InsertBefore(&nhtml.Node{
				FirstChild: &nhtml.Node{
					Type: nhtml.TextNode,
					Data: os.FirstChild.Data,
				},
				Type:     nhtml.ElementNode,
				DataAtom: atom.Td,
				Data:     "td",
				Attr: []nhtml.Attribute{
					{
						Key: "class",
						Val: "foot-los",
					},
				},
			}, n.FirstChild)
			os.Attr[0].Val = "foot-ros"
		}

		for i, a := range n.Attr {
			if a.Key == "id" || a.Key == "href" && strings.HasPrefix(a.Val, "#") {
				n.Attr[i].Val = formatId(a.Val)
			}
		}

		b := strings.Builder{}
		b.WriteByte('<')
		if n.Namespace != "" {
			b.WriteString(n.Namespace)
			b.WriteByte(':')
		}
		b.WriteString(n.Data)

		for _, a := range n.Attr {
			b.WriteString(" ")
			if a.Namespace != "" {
				b.WriteString(a.Namespace)
				b.WriteByte(':')
			}
			b.WriteString(a.Key)
			b.WriteString("=\"")
			b.WriteString(a.Val)
			b.WriteByte('"')
		}

		if n.FirstChild == nil {
			b.WriteString(" />")
		} else {
			b.WriteByte('>')
		}
		fmt.Print(b.String())
	case nhtml.DoctypeNode:
		fmt.Print("<!DOCTYPE html>")
	}

	for c := n.FirstChild; c != nil; c = c.NextSibling {
		handleNode(c)
	}

	if n.Type == nhtml.ElementNode && n.FirstChild != nil {
		fmt.Print("</" + n.Data + ">")
	}
}

func die(err error) {
	fmt.Fprintf(os.Stderr, "%s: %s\n", os.Args[0], err)
	os.Exit(1)
}
