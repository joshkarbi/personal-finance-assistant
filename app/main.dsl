context
{
    input endpoint: string;
    
    // declare input variables here
    
    // declare storage variables here
    spendAmount: string = "unknown";
    place: string = "unknown";
    typeOfRestaurant: string = "x";
    question: string = "x";
    
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
    input salary: string = "80000";
    input monthlySpend: string = "1500";
    input cashSavings: string = "1000";
    input investments: string = "5000";
    
    // declare storage variables here
    currentMonth: string = "11";
    currentYear: string = "2021";
    monthlySavings: string = "";
    monthsToGoal: number = 0;
}

// declare external functions here
external function confirm(secretWord: string): boolean;
external function getClientName(secretWord: string): string;
external function status(): string;
external function canAffordExpense(cost: string): boolean;
external function canGoToPlace(place: string): boolean;
external function restaurantRecommend(maxMoneySigns: string, distance: string, typeRestaurant: string): string;
external function getAge(): number;
external function calculateMonthlySavings(salary: string, monthlySpend: string): string;
external function calculateMonthsToGoal(monthlySavings: string, investments: string, cash: string, goalAmount: string): number;

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
        #sayText("Type of restaurant is " + $typeOfRestaurant);
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
        set $monthlySavings = external calculateMonthlySavings($salary, $monthlySpend);
        #sayText("Based on your current salary of " + $salary + " dollars and monthly spend of "
        + $monthlySpend + " dollars, you are saving " + $monthlySavings + " dollars per month.");
        set $monthsToGoal = external calculateMonthsToGoal($monthlySavings, $cashSavings, $investments, $savingsGoal.amount);
        
        #sayText("Given that you also have " + $cashSavings + " dollars in savings, and " + $investments
        + " dollars in investments, if you continue saving this much you will reach your goal in " + #stringify($monthsToGoal) + " months!");
        
        if($monthsToGoal < $savingsGoal.months)
        {
            #sayText("Keep up the good work and you'll be well on your way!");
        }
        else
        {
            #sayText("Let me know if you'd like to learn about strategies to help you save money.");
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
            var name = external getClientName(fruit);
            #sayText("Hi, " + name + "! Your identity is confirmed. Let me just check your status. ");
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
