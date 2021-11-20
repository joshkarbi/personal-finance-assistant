/**
 * Various financial utility functions.
 * 
 * Setting budgets, estimate the cost of going to a restaurant, etc.
 */

async function getMarginalTaxOwing(brackets, rates, grossSalary) {
    var result = 0;
    var i = 0;

    while (grossSalary > 0) {
        var amountInBracket = min(brackets[i], grossSalary);
        result += rates[i] * amountInBracket;

        grossSalary = grossSalary - amountInBracket;
        i += 1
    }

    return result;
}

async function getYearlyFederalTaxAmount(grossAnnualSalary) {
    var brackets = [49020, 49020, 53939, 64533, 999999999];
    var rates = [0.15, 0.205, 0.26, 0.29, 0.33];
    
    return await getMarginalTaxOwing(brackets, rates, grossAnnualSalary);
}

async function getYearlyProvincialTaxAmount(grossAnnualSalary) {
    var brackets = [45142, 45142, 90287, 150000, 9999999];
    var rates = [5.05 / 100, 9.15 / 100, 11.16/100, 12.16/100, 13.16/100];
    
    return await getMarginalTaxOwing(brackets, rates, grossAnnualSalary);
}

async function getYearlyCPPContributionWitheld(grossAnnualSalary) {
    return (grossAnnualSalary - 3500)* 5.45/100;
}

async function getYearlyEIPremium(grossAnnualSalary) {
    return min(grossAnnualSalary, 56300) * 1.58/100;
}

async function getNetMonthlyIncome(grossAnnualSalary) {
    var yearlyNetIncome = grossAnnualSalary - (
        await getYearlyFederalTaxAmount(grossAnnualSalary) -
        await getYearlyProvincialTaxAmount(grossAnnualSalary) -
        await getYearlyCPPContributionWitheld(grossAnnualSalary) -
        await getYearlyEIPremium(grossAnnualSalary)
    );

    return yearlyNetIncome / 12;
}

// return monthly budget breakdown in form: {needs: number, wants: number, savings: number}
async function createMonthlyBudget(grossAnnualSalary) {
    var monthlyNetIncome = await getNetMonthlyIncome(grossAnnualSalary);
    return {
        needs: 0.50 * monthlyNetIncome,
        wants: 0.30 * monthlyNetIncome,
        savings: 0.20 * monthlyNetIncome
    };
}

// given "Montana's" look up the prices.
async function estimateCostOfRestaurant(place) {

}

module.exports = { createMonthlyBudget, estimateCostOfRestaurant };