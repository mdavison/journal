//
//  Calendar.swift
//  Journal
//
//  Created by Morgan Davison on 5/26/16.
//  Copyright © 2016 Morgan Davison. All rights reserved.
//

//import Foundation
import UIKit

class Calendar {
    
    var currentCalendar = NSCalendar.currentCalendar()

    func getMonthsYears(forEntries entries: [Entry]) -> [MonthYear] {
        var monthsYears = [MonthYear]()
        //let currentCalendar = NSCalendar.currentCalendar()
        let monthSpan = getNumberOfMonths(forEntries: entries)
        
        if let firstEntryDate = entries.first?.created_at {
            let components = currentCalendar.components([.Month, .Year], fromDate: firstEntryDate)
            
            // Create var to hold month component of each item in the loop,
            // Initial value set to first headache
            var nsDateCounter = currentCalendar.dateFromComponents(components)
            
            if monthSpan > 0 {
                for _ in 1...monthSpan {
                    let components = currentCalendar.components([.Month, .Year], fromDate: nsDateCounter!)
                    var entriesArray = [Entry]()
                    
                    for entry in entries {
                        // Get month and year components from the entry
                        let entryComponents = currentCalendar.components([.Month, .Year], fromDate: entry.created_at!)
                        // When they match the outer loop components, add to entry array
                        if (entryComponents.month == components.month) && (entryComponents.year == components.year) {
                            entriesArray.append(entry)
                        }
                    }
                    
                    let monthYear = MonthYear(month: components.month, year: components.year, entries: entriesArray)
                    monthsYears.append(monthYear)
                    
                    // decrement nsDateCounter by 1 month
                    nsDateCounter = currentCalendar.dateByAddingUnit(.Month, value: -1, toDate: nsDateCounter!, options: [])
                }
            }
        }

        return monthsYears
    }
    
    func getNumberOfMonths(forEntries entries: [Entry]) -> Int {
        //let calendar = NSCalendar.currentCalendar()
        
        // Get the number of months between the first and last entry
        if !entries.isEmpty {
            // Get month for last entry
            if let lastEntryDate = entries.last?.created_at {
                let dateComponentsOfLastEntry = currentCalendar.components([.Month, .Year], fromDate: lastEntryDate)
                // Set last date to be the first of the month, as partial months don't get counted
                let modifiedLastDate = currentCalendar.dateFromComponents(dateComponentsOfLastEntry)
                let months = currentCalendar.components(NSCalendarUnit.Month, fromDate: modifiedLastDate!, toDate: entries.first!.created_at!, options: [])
                
                //return months.month
                return months.month + 1 // Need to add one to make sure it includes the last one?
            }
        }
        return 0
    }
    
    func numberOfDaysInMonth(forMonthAndYear monthYear: MonthYear) -> Int {
        //let calendar = NSCalendar.currentCalendar()
        let date = getNSDateFromComponents(monthYear.year, month: monthYear.month, day: nil)
        let numberOfDaysInMonth = currentCalendar.rangeOfUnit(.Day, inUnit: .Month, forDate: date)
        let padding = getPadding(forMonthAndYear: monthYear)
        
        return numberOfDaysInMonth.toRange()!.last! + padding
    }
    
    func configureCell(forCell cell: CalendarCollectionViewCell, withIndexPath indexPath: NSIndexPath, withMonthsYears monthsYears: [MonthYear]) {
        cell.backgroundColor = UIColor.whiteColor()
        
        // Create top border
        let topBorder = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width + 1, height: 1))
        topBorder.backgroundColor = UIColor.lightGrayColor()
        cell.contentView.addSubview(topBorder)
        
        // Determine if this cell should be empty
        let padding = getPadding(forMonthAndYear: monthsYears[indexPath.section])
        var day = 0
        
        if indexPath.row + 1 > padding {
            day = (indexPath.row + 1) - padding
        }
        
        if day > 0 { // Not a blank cell
            cell.dayNumberLabel.text = "\(day)"
            
            //showEntryIfExists(forCell: cell, andIndexPath: indexPath, andDay: day)
            
            // Show entry or mark if today
            setIndication(forCell: cell, withIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears)
        } else { // Cell is a blank padding cell
            cell.dayNumberLabel.text = ""
        }
    }
    
    func getDate(forIndexPath indexPath: NSIndexPath, withDay day: Int, withMonthsYears monthsYears: [MonthYear]) -> NSDate {
        return getNSDateFromComponents(monthsYears[indexPath.section].year, month: monthsYears[indexPath.section].month, day: day)
    }
    
    func getEntry(forIndexPath indexPath: NSIndexPath, withDay day: Int, withMonthsYears monthsYears: [MonthYear]) -> Entry? {
        let selectedDate = getDate(forIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears)
        let entriesForThisMonth = monthsYears[indexPath.section].entries
        
        for entry in entriesForThisMonth {
            if let entryDate = entry.created_at {
                // Extract the components from the entry date so the hours are the same as the selectedDate
                let entryDateComponents = currentCalendar.components([.Year, .Month, .Day], fromDate: entryDate)
                let entryDateFromComponents = getNSDateFromComponents(entryDateComponents.year, month: entryDateComponents.month, day: entryDateComponents.day)
                
                if entryDateFromComponents == selectedDate {
                    return entry
                }
            }
        }
        
        return nil
    }
    
    func dateIsFuture(forCollectionView collectionView: UICollectionView?, withMonthsYears monthsYears: [MonthYear]) -> Bool {
        guard let indexPaths = collectionView?.indexPathsForSelectedItems(),
            let cell = collectionView?.cellForItemAtIndexPath(indexPaths[0]) as? CalendarCollectionViewCell,
            let dayString = cell.dayNumberLabel.text,
            let day = Int(dayString) else { return false }
        
        let date = getDate(forIndexPath: indexPaths[0], withDay: day, withMonthsYears: monthsYears)
        let comparison = currentCalendar.compareDate(date, toDate: NSDate(), toUnitGranularity: .Day)
        
        if comparison == .OrderedDescending { // Is future
            return true
        }
        
        return false
    }
    
    func getHeaderView(forCollectionView collectionView: UICollectionView, withIndexPath indexPath: NSIndexPath, withMonthsYears monthsYears: [MonthYear]) -> CalendarCollectionReusableHeaderView {
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "Header", forIndexPath: indexPath) as! CalendarCollectionReusableHeaderView
        
        headerView.backgroundColor = UIColor(red: 230.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1)
        
        let dateFormatter = NSDateFormatter()
        let monthText = dateFormatter.shortMonthSymbols[monthsYears[indexPath.section].month - 1]
        let yearText = monthsYears[indexPath.section].year
        
        headerView.titleLabel.text = "\(monthText) \(yearText)".uppercaseString
        
        return headerView
    }

    
    private func getNSDateFromComponents(year: Int, month: Int, day: Int?) -> NSDate {
        //let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.month = month
        components.year = year
        if let day = day {
            components.day = day
        }
        
        return currentCalendar.dateFromComponents(components)!
    }
    
    private func getPadding(forMonthAndYear monthAndYear: MonthYear) -> Int {
        // Get day of the week for the first day of the month
        let date = getNSDateFromComponents(monthAndYear.year, month: monthAndYear.month, day: 1)
        let components = currentCalendar.components([.Weekday], fromDate: date)
        
        return components.weekday - 1
    }
    
    private func setIndication(forCell cell: UICollectionViewCell, withIndexPath indexPath: NSIndexPath, withDay day: Int, withMonthsYears monthsYears: [MonthYear]) {
        // Indicate entry for this date
        if let _ = getEntry(forIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears) {
            cell.backgroundColor = UIColor.lightGrayColor()
        }
        
        // Indicate today
        // TODO: draw a red circle around the number instead of making the background red
        let date = getDate(forIndexPath: indexPath, withDay: day, withMonthsYears: monthsYears)
        let comparison = currentCalendar.compareDate(date, toDate: NSDate(), toUnitGranularity: .Day)
        if comparison == .OrderedSame {
            cell.backgroundColor = UIColor.redColor()
        }
    }

}