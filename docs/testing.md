# Testing

Three tiers, one vocabulary for test doubles, and one rule about where a double
lives. Everything here is enforced by `keystone-swift` except where it says
otherwise — and where it says otherwise, the reason is given, because a
convention nobody can check is one somebody has to remember.

---

## The vocabulary

The taxonomy is Gerard Meszaros', from *xUnit Test Patterns* (2007). Martin
Fowler's [Mocks Aren't Stubs](https://martinfowler.com/articles/mocksArentStubs.html)
is what made it common currency.

**Test Double** is the family name, not a member of the family. Meszaros coined
it — from a stunt double — precisely because "mock" had come to mean all five.

| Kind | What it does | Reach for it when |
| --- | --- | --- |
| **Dummy** | Filler. Passed in, never used. | A parameter must be supplied and the test does not care |
| **Stub** | Canned answers. Records nothing. | The collaborator has to *say* something |
| **Spy** | A stub that records how it was called | You need to assert the collaborator *was told* something |
| **Mock** | Pre-programmed expectations that verify themselves | Same, but the failure comes from inside the collaborator |
| **Fake** | A working implementation, unfit for production | You want real behaviour cheaply — an in-memory repository |

The kind is in the name because the kind decides what the test can assert.
Fowler's cut: a **stub supports state verification**, a **mock supports
behaviour verification**. A spy is the middle — it records like a mock and is
asserted on like a stub, which is why it is usually the right one.

This codebase has **no mocks**, deliberately. See *Where we stand*, below.

### Not doubles

Two other things live in test support and are not doubles.

**Builders** make test data — `pid(_:)`, `Product.fixture`, `AProduct()`. From
Freeman & Pryce, *Growing Object-Oriented Software* (2009), Ch. 22. Each test
sets only the field it cares about and inherits the rest.

A **fixture**, in Meszaros' sense, is the state a test runs against — not a
thing you pass in. A *shared* fixture is one of his named smells: data no test
owns, which nobody can change safely and everybody reads. Builders exist to
avoid it, and `no-shared-fixtures` reports one if it reappears.

**Drivers** are the acceptance suite's vocabulary — `Shopper`, `Buyer`,
`Waiter`, `Saver`. Martin's Testing API, *Clean Architecture* (2017), Ch. 28:
tests speak the business's language through a driver, so the system underneath
can be rearranged without touching them.

---

## Where a double lives

**A double belongs to the package that declares the protocol it stands in for**,
published from that package as a `<Package>TestSupport` product.

This is the rule that stops doubles multiplying. When callers write their own,
one protocol collects a stub per consumer, each drifting from the real behaviour
on its own schedule while every suite goes on passing. It is the argument in
*Software Engineering at Google* (Winters, Manshreck & Wright, 2020, Ch. 13) for
the API's owner writing the fake, and the Swift ecosystem does it structurally:
[swift-nio](https://github.com/apple/swift-nio) ships `NIOEmbedded` beside the
protocols it doubles, and
[swift-dependencies](https://github.com/pointfreeco/swift-dependencies) puts
`testValue` in the same declaration as the interface.

Enforced by `doubles-live-with-their-protocol`. It stands down in one case:
where moving the double would turn a dependency around. `FakeCatalog` fakes
`Networking`'s `HTTPClient` but is built out of `Product`'s payload types, and a
library cannot be made to learn about a component in order to hold a fake.

### Layout

```
Component/Bag/Sources/TestSupport/
  Stubs/StubObserveBag.swift
  Spies/SpyAddItemToBag.swift
  Fakes/InMemoryBagRepository.swift
  Builders/bagItem.swift
```

One file per double, in a directory named for its kind. A file holding four
stubs, three spies and two fakes tells a reader nothing about where to look, and
every change to any of them touches it.

Everything is `public`. A shared module is consumed with a plain `import`;
`@testable` is not a substitute, because it compiles against internal members
and then fails at the link step.

Waiting helpers are in `Library/AsyncTesting` — no component owns them, the same
reason `Networking` is a library.

---

## The tiers

| Tier | Answers | Named in |
| --- | --- | --- |
| **Acceptance** | Does the feature work? | the business's language, as prose |
| **Unit** | Is the code right? | the language of the system |
| **Snapshot** | Does the screen look right? | either |

Freeman & Pryce's two loops (*GOOS*, Ch. 1): the acceptance test drives the
feature from outside, the unit tests drive the design from within.

A component owes acceptance and unit tiers. A UI package earns a unit tier by
having a view model and a snapshot tier by having a view — a package of nothing
but views has no unit for a unit test to name. Enforced by `tier-required`.

### What each tier may fake

**The tier decides what you are allowed to double**, and doubles get fewer and
further out as you climb:

- an **acceptance** test fakes the system's edges — network, disk, other
  components — and runs the real use cases, entities and rules in between
- a **unit** test fakes the unit's immediate collaborators, because those are
  exactly what it is isolating from
- a **snapshot** test fakes whatever gets the view into a state

`FakeShop` is the shape to copy: it fakes where the bag is kept and what the
catalogue answers, and vends the *real* Bag use cases, so a total on the screen
was computed by real arithmetic.

**This one is not checked, and cannot be.** How far in to fake depends on what
the screen does with the data. `BagUI` runs the real bag use cases because its
screen shows a total; `HomeUI` stubs `DrawHomeFeedUseCase` because its screen
only renders what it is handed, and the feed rules are already covered by
`Component/Home`'s own acceptance suite. Both are correct, and a rule strict
enough to catch a real slip would call one of them wrong. Written down instead.

### The pyramid

`test-pyramid` exists and is **off unless `tests.pyramid` names an order**.

The pyramid is about cost and scope — how much of the system a test exercises,
how slow it is, how often it breaks for reasons unrelated to the change.
Counting files in directories stands in for that only when the tiers really do
differ in cost. Here they do not: the acceptance suites run in-process against
in-memory fakes, which by Ham Vocke's taxonomy in
[The Practical Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html)
makes them mid-pyramid service tests phrased in the business's language.
Acceptance testing is a *purpose*, not a level.

Run it and the evidence is plain: the classic order flags six packages, the
reverse flags ten. A rule that finds fault whichever way round you put it is
not measuring the thing it names.

---

## BDD

[Cucumber's own docs](https://cucumber.io/docs/bdd/) put BDD as three practices,
and Gherkin appears only in the second:

1. **Discovery** — conversations about real examples. *"The hardest single part
   of building a software system is deciding precisely what to build."*
2. **Formulation** — writing those examples in a medium readable by humans and
   computers
3. **Automation** — the example becomes a failing test, then a passing one

Formulation here is a `@Suite` naming the rule and `@Test` naming the example,
in the shopper's words:

```swift
@Suite("A bag is worth the sum of what is in it")
struct UsingTheBagTests {
    @Test("A shopper chooses two things and their bag is worth what they agreed to pay")
    func choosesTwoThings() async {
        let shopper = Shopper()                        // Given

        shopper.choose(productId: 1, atPrice: 9.99)    // When
        shopper.choose(productId: 2, atPrice: 49.99)

        #expect(shopper.bag.total == usd(59.98))       // Then
    }
}
```

No Gherkin runner. The maintained ones for Swift do not exist, and a `.feature`
file buys an indirection between the sentence and the code for a benefit that
`@Test("…")` already gives. What a runner would *not* give is the part that
matters: `acceptance-vocabulary` refuses an acceptance test that names a type
the data layer declared. Cucumber would happily execute a feature file full of
`FakeCatalog`.

Enforced: `test-names-read-as-prose` on the acceptance tier.
Not enforced: that Discovery happened at all. Nothing can check that.

---

## Where we stand

**No mocks, 0 of 42 doubles.** That is Google's advice in Ch. 13 — prefer real
implementations, then fakes, stub sparingly, avoid mocking frameworks — because
over-mocked tests assert on implementation and break on every refactor. Freeman
& Pryce would argue the other way, and their argument is worth knowing: for
them a mock is a *design* tool, and a mock that is painful to set up is telling
you the collaboration is wrong. We have taken Google's side; a mock here would
not be a violation so much as a question worth asking out loud.

**No `@unchecked Sendable` where the compiler could check it instead.** On a
main-actor isolated double it says nothing a `@MainActor` class does not
already say, and a double that keeps its state behind a `Mutex` is `Sendable`
by construction, so the compiler checks what the annotation only asks you to
believe. Two remain, both in test folders behind an `NSLock`.

**Evans** is absent from this page and present in the code: DDD does not discuss
doubles, but it supplies the language the drivers speak, and the Repository
pattern is what makes an in-memory fake the natural thing to write.
