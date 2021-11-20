context
{
    input endpoint: string;
    
    // declare input variables here
    input firstName: string = "Dalton";  // fetch this from DB at some point
    
    // declare storage variables here
    spendAmount: string = "unknown";
    place: string = "unknown";
}

// declare external functions here
external function confirm(fruit: string): boolean;
external function status(): string;
external function canAffordExpense(cost: string): boolean;
external function canGoToPlace(place: string): boolean;

// welcome node
start node root
{
    do
    {
        #connectSafe($endpoint);
        #waitForSpeech(1000);
        #sayText("Hello " + $firstName + " , I'm Dasha, your personal finance assistant. How can I help you today?");
        wait *;
    }
    transitions
    {
    }
}

// this is the node to come back to if you want to do another transaction
node what_else
{
    do
    {
        #sayText("What else can I help you with?");
        wait *;
    }
}

digression spend_amount
{
    conditions
    {
        on #messageHasIntent("spend");
    }
    do
    {
        set $spendAmount = #messageGetData("spend_amount")[0]?.value??"";
        var canAfford = external canAffordExpense($spendAmount);
        if (canAfford)
        {
            #sayText("Go for it! You can afford to spend " + $spendAmount + " dollars!");
        }
        else
        {
            #sayText("I'm sorry, you can't afford to spend " + $spendAmount + " dollars. You are broke.");
        }
        #sayText("Can I help you with anything else today?");
        wait *;
    }
    transitions
    {
        bye_then: goto bye_then on #messageHasIntent("no");
        what_else: goto what_else on #messageHasIntent("yes");
    }
}

digression place
{
    conditions
    {
        on #messageHasIntent("goToPlace");
    }
    do
    {
        set $place = #messageGetData("place")[0]?.value??"";
        var canAfford = external canGoToPlace($place);
        if (canAfford)
        {
            #sayText("Go for it! You can afford to go to" + $place + "!");
        }
        else
        {
            #sayText("I'm sorry, you can't afford to go to " + $place);
        }
        #sayText("Can I help you with anything else today?");
        wait *;
    }
    transitions
    {
        bye_then: goto bye_then on #messageHasIntent("no");
        what_else: goto what_else on #messageHasIntent("yes");
    }
}

digression savings_goal
{
    conditions
    {
        on #messageHasIntent("check_savings_goal");
    }
    do
    {
    }
    transitions
    {
    }
}

// acknowledge flow begins
digression status
{
    conditions
    {
        on #messageHasIntent("status");
    }
    do
    {
        #sayText("Great! To tell you your ACME Rockets application status, I need to confirm your identity.");
        #sayText("It seems that you are logged in as Mr. Wile E. Coyote. Can you please confirm the answer to the secret question.");
        #sayText("What is your favourite fruit?");
        wait *;
    }
    
    transitions
    {
        confirm: goto confirm on #messageHasData("fruit");
    }
}

node confirm
{
    do
    {
        var fruit = #messageGetData("fruit",
        {
            value: true
        }
        )[0]?.value??"";
        var response = external confirm(fruit);
        if (response)
        {
            #sayText("Great, identity confirmed. Let me just check your status. ");
            goto approved;
        }
        else
        {
            #sayText("I'm sorry but your identity is not confirmed. Let's try again. What is your favourite fruit?");
            wait *;
        }
    }
    
    transitions
    {
        approved: goto approved;
        confirm: goto confirm on #messageHasData("fruit");
    }
}

node approved
{
    do
    {
        var status = external status();
        #sayText(status);
        #sayText("Anything else I can help you with today?");
        wait *;
    }
    
    transitions
    {
        can_help: goto can_help on #messageHasIntent("yes");
        bye_then: goto bye_then on #messageHasIntent("no");
    }
}

node bye_then
{
    do
    {
        #sayText("Thank you and have a great day! Mazeltov!");
        exit;
    }
}

node can_help
{
    do
    {
        #sayText("Right. How can I help you? ");
        wait*;
    }
}

digression bye
{
    conditions
    {
        on #messageHasIntent("bye");
    }
    do
    {
        #sayText("Thank you and happy trails! ");
        exit;
    }
}

// additional digressions
digression @wait
{
    conditions
    {
        on #messageHasAnyIntent(digression.@wait.triggers)  priority 900;
    }
    var triggers = ["wait", "wait_for_another_person"];
    var responses: Phrases[] = ["i_will_wait"];
    do
    {
        for (var item in digression.@wait.responses)
        {
            #say(item, repeatMode: "ignore");
        }
        #waitingMode(duration: 70000);
        return;
    }
    transitions
    {
    }
}

digression repeat
{
    conditions
    {
        on #messageHasIntent("repeat");
    }
    do
    {
        #repeat();
        return;
    }
}
