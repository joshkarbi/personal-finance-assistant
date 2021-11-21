context
{
    input endpoint: string;
    
    // declare input variables here
    
    // declare storage variables here
    spendAmount: string = "unknown";
    place: string = "unknown";
    typeOfRestaurant: string = "x";
    question: string = "x";
    
    clientInfo:
    {
        item: string; name: string; age: number;
        grossAnnualSalary: number; monthlySpend: number;
        cashSavings: number; secretWord: string;
    }
    =
    {
        item: "unknown", name: "unknown", age: 1, grossAnnualSalary: 0, monthlySpend: 0,
        cashSavings: 0, secretWord: "unknown"
    }
    ;
    
    // inputs for check_savings_goal flow
    input savingsGoal:
    {
        item: string;
        amount: string;
        months: number;
    }
    =
    {
        item: "car",
        amount: "20000",
        months: 10
    }
    ;
    // input salary: string = "80000";
    // input monthlySpend: string = "1500";
    input cashSavings: string = "1000";
    input investments: string = "5000";
    
    // declare storage variables here
    currentMonth: string = "11";
    currentYear: string = "2021";
    monthlySavings: number = 0;
    monthsToGoal: number = 0;
}

// declare external functions here
external function confirm(secretWord: string): boolean;
external function status(): string;
external function canAffordExpense(cost: string): boolean;
external function canGoToPlace(place: string): boolean;
external function restaurantRecommend(maxMoneySigns: string, distance: string, typeRestaurant: string): string;
external function getAge(): number;
external function calculateMonthlySavings(grossAnnualSalary: number, monthlySpend: number): number;
external function calculateMonthsToGoal(monthlySavings: number, investments: string, cash: string, goalAmount: string): number;
external function getClientInfo(secretWord: string):
{
    item: string; name: string; age: number;
    grossAnnualSalary: number; monthlySpend: number;
    cashSavings: number; secretWord: string;
}
;

// welcome node
start node root
{
    do
    {
        #connectSafe($endpoint);
        #waitForSpeech(1000);
        #sayText("Hello, I'm Dasha, your personal finance assistant. Before we begin, I need to confirm your identity.");
        #sayText("Can you please confirm the answer to the security question.");
        #sayText("What is your secret word?");
        wait *;
    }
    transitions
    {
        confirm: goto confirm on #messageHasData("fruit");
    }
}

// this is the node to come back to if you want to do another transaction
node what_else
{
    do
    {
        #sayText("What can I help you with?");
        wait *;
    }
    transitions
    {
        spend: goto spend_amount on #messageHasIntent("spend");
        savings: goto savings_goal on #messageHasIntent("check_savings_goal");
        investment_advice: goto investment_advice on #messageHasIntent("advice");
    }
}

node investment_advice
{
    do
    {
        #sayText("Sure! Let me start with a few basic questions to see what type of investments would be suitable for you.");
        #sayText("Would you like to be active or passive in managing your investments?");
        wait *;
    }
    transitions
    {
        investment_involvement: goto investment_involvement on #messageHasData("involvement");
    }
}

node investment_involvement
{
    do
    {
        var involvement = #messageGetData("involvement",
        {
            value: true
        }
        )[0]?.value??"";
        if (involvement == "active")
        {
            #sayText("Okay, for active investors I recommend Scotia eye Trade, where you can see directly into your invesments. I'm a bit of an investor myself, would you like some tips?");
            wait *;
        }
        else
        {
            // nothing for now
        }
    }
    transitions
    {
        what_else: goto what_else on #messageHasIntent("no");
        tips: goto tips on #messageHasIntent("yes");
    }
}

node tips
{
    do
    {
        #sayText("Okay! My advice is simple. Buy GameStop, hold, and watch it go to the MOOOOON!");
        #sayText("Can I help you with anything else today?");
        wait *;
    }
    transitions
    {
        bye_then: goto bye_then on #messageHasIntent("no");
        what_else: goto what_else on #messageHasIntent("yes");
    }
}

node spend_amount
{
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
        on #messageHasData("place");
    }
    do
    {
        set $place = #messageGetData("place")[0]?.value??"";
        var canAfford = external canGoToPlace($place);
        if (canAfford)
        {
            #sayText("Go for it! You can afford to go to" + $place + "!");
            #waitForSpeech(20000);
            #sayText("Can I help you with anything else today?");
            set $question = "canAfford";
        }
        else
        {
            #sayText("I'm sorry, you can't afford to go to " + $place);
            #sayText("Do you want a recommendation for a more affordable place to eat?");
            set $question = "cantAfford";
        }
        wait *;
    }
    transitions
    {
        what_else: goto what_else on #messageHasIntent("no") && $question=="cantAfford";
        bye_then: goto bye_then on #messageHasIntent("no") && $question=="canAfford";
        ask_restaurant_type: goto ask_restaurant_type on #messageHasIntent("yes");
    }
}

node ask_restaurant_type
{
    do
    {
        #sayText("What type of restaurant do you want to dine at?");
        wait *;
    }
    transitions
    {
        ask_distance: goto ask_distance on #messageHasData("restaurantType");
        bye_then: goto bye_then on #messageHasIntent("no");
    }
}

node ask_distance
{
    do
    {
        set $typeOfRestaurant = #messageGetData("restaurantType",
        {
            value: true
        }
        )[0]?.value??"";
        #sayText("What is the farthest distance in kilometres you are willing to travel?");
        wait *;
    }
    transitions
    {
        distance: goto restaurantRecommend on #messageHasData("distance");
        bye_then: goto bye_then on #messageHasIntent("no");
    }
}

node restaurantRecommend
{
    do
    {
        var distance = #messageGetData("distance",
        {
            value: true
        }
        )[0]?.value??"";
        var newPlace = external restaurantRecommend("1", distance, $typeOfRestaurant);
        #sayText("I recommend you eat at the restaurant called " + newPlace);
        #waitForSpeech(20000);
        #sayText("Is there anything else I can help you with today?");
        wait *;
    }
    transitions
    {
        bye_then: goto bye_then on #messageHasIntent("no");
        what_else: goto what_else on #messageHasIntent("yes");
    }
}

digression invest
{
    conditions
    {
        on #messageHasIntent("invest");
    }
    do
    {
        var age = external getAge();
        if (age < 25)
        {
            #sayText("Given that you are less than 25 and have a long time horizon to invest I recommend buying Scotia Global Growth ETF");
        }
        else if( age > 25 && age <= 50)
        {
            #sayText("Given that you are between 25 and 50 and have a need for growth but wealth stability I recommend buying Scotia Large CAP ETF");
        }
        else
        {
            #sayText("Given that you are greater than  than 25 and will be requiring funds soon for retirement I recommend buying Scotiabank's Low Beta ETF");
        }
        #sayText("Is there anything else I can help you with today?");
        wait *;
    }
    transitions
    {
        bye_then: goto bye_then on #messageHasIntent("no");
        what_else: goto what_else on #messageHasIntent("yes");
    }
}

node savings_goal
{
    do
    {
        #sayText("Sure, let me take a look at your goal of saving " + $savingsGoal.amount + " dollars for a " + $savingsGoal.item);
        set $monthlySavings = external calculateMonthlySavings($clientInfo.grossAnnualSalary, $clientInfo.monthlySpend);
        #sayText("Based on your current salary of " + #stringify($clientInfo.grossAnnualSalary) + " dollars and monthly spend of "
        + #stringify($clientInfo.monthlySpend) + " dollars, you are saving " + #stringify($monthlySavings) + " dollars per month.");
        set $monthsToGoal = external calculateMonthsToGoal($monthlySavings, $cashSavings, $investments, $savingsGoal.amount);
        
        #sayText("Given that you also have " + $cashSavings + " dollars in savings, and " + $investments
        + " dollars in investments, if you continue saving this much you will reach your goal in " + #stringify($monthsToGoal) + " months!");
        
        if($monthsToGoal < $savingsGoal.months)
        {
            #sayText("Keep up the good work and you'll be well on your way!");
        }
        else
        {
            #sayText("It looks like you're going to be just short of your goal");
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

// acknowledge flow begins
digression status
{
    conditions
    {
        on #messageHasIntent("status");
    }
    do
    {
        #sayText("Great! I need to confirm your identity.");
        #sayText("Can you please confirm the answer to the secret question.");
        #sayText("What is your favourite fruit?");
        wait *;
    }
    
    transitions
    {
        confirm: goto confirm on #messageHasData("fruit");
        investment_advice: goto investment_advice on #messageHasIntent("advice");
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
            set $clientInfo = external getClientInfo(fruit);
            
            #sayText("Hi, " + $clientInfo.name + "! Your identity is confirmed.");
            
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
        approved: goto what_else;
        confirm: goto confirm on #messageHasData("fruit");
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
        #sayText("Thank you goodbye! ");
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
