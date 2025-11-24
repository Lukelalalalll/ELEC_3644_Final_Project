//
//  CourseData.swift
//  ELEC_3644_Final_Project
//
//  Created by victor 徐 on 21/11/2025.
//

import Foundation

// 创建8门完整的课程数据
func createSampleCourses() -> [Course] {
    var courses: [Course] = []
    
    let elec3644 = Course(
        courseId: "ELEC3644",
        courseName: "Advanced mobile apps development",
        professor: "Prof. Zhang",
        courseCode: "ELEC3644",
        credits: 6,
        courseDescription: "This course aims to provide students with advanced knowledge and programming skill to develop innovative and sophisticated mobile apps on iOS platfom. "
    )
    
    // 添加上课时间
    elec3644.addClassTime(
        dayOfWeek: 1, // Monday
        startTime: createTime(hour: 9, minute: 0),
        endTime: createTime(hour: 10, minute: 30),
        location: "Engineering Building Room 301"
    )
    elec3644.addClassTime(
        dayOfWeek: 3, // Wednesday
        startTime: createTime(hour: 14, minute: 0),
        endTime: createTime(hour: 15, minute: 30),
        location: "Engineering Building Room 301"
    )
    
    // 添加作业
    elec3644.addHomework(
        homeworkId: "ELEC3644_LAB",
        title: "Lab",
        dueDate: createDate(month: 10, day: 30, hour: 23, minute: 59)
    )
    elec3644.addHomework(
        homeworkId: "ELEC3644_MIDTERM",
        title: "Midterm",
        dueDate: createDate(month: 11, day: 10, hour: 23, minute: 59)
    )
    
    courses.append(elec3644)
    
    // 2. COMP2119 - Introduction to Data Structures and Algorithms
    let comp2119 = Course(
        courseId: "COMP2119",
        courseName: "Introduction to Data Structures and Algorithms",
        professor: "Prof. Li",
        courseCode: "COMP2119",
        credits: 4,
        courseDescription: "Fundamental data structures and algorithms including arrays, linked lists, trees, sorting, and searching algorithms."
    )
    
    comp2119.addClassTime(
        dayOfWeek: 2, // Tuesday
        startTime: createTime(hour: 10, minute: 0),
        endTime: createTime(hour: 11, minute: 30),
        location: "Computer Science Building Room 201"
    )
    comp2119.addClassTime(
        dayOfWeek: 4, // Thursday
        startTime: createTime(hour: 10, minute: 0),
        endTime: createTime(hour: 11, minute: 30),
        location: "Computer Science Building Room 201"
    )
    
    comp2119.addHomework(
        homeworkId: "COMP2119_HW1",
        title: "Homework",
        dueDate: createDate(month: 11, day: 5, hour: 23, minute: 59)
    )
    comp2119.addHomework(
        homeworkId: "COMP2119_PROJ",
        title: "Project",
        dueDate: createDate(month: 11, day: 20, hour: 23, minute: 59)
    )
    
    courses.append(comp2119)
    
    // 3. COMP3230 - Computer Architecture
    let comp3230 = Course(
        courseId: "COMP3230",
        courseName: "Computer Architecture",
        professor: "Prof. Wang",
        courseCode: "COMP3230",
        credits: 3,
        courseDescription: "Study of computer organization and architecture, including processor design, memory systems, and I/O organization."
    )
    
    comp3230.addClassTime(
        dayOfWeek: 1, // Monday
        startTime: createTime(hour: 13, minute: 0),
        endTime: createTime(hour: 14, minute: 30),
        location: "Computer Science Building Room 305"
    )
    comp3230.addClassTime(
        dayOfWeek: 4, // Thursday
        startTime: createTime(hour: 13, minute: 0),
        endTime: createTime(hour: 14, minute: 30),
        location: "Computer Science Building Room 305"
    )
    
    comp3230.addHomework(
        homeworkId: "COMP3230_PROJ",
        title: "Project",
        dueDate: createDate(month: 11, day: 15, hour: 23, minute: 59)
    )
    comp3230.addHomework(
        homeworkId: "COMP3230_REPORT",
        title: "Final Report",
        dueDate: createDate(month: 12, day: 1, hour: 23, minute: 59)
    )
    
    courses.append(comp3230)
    
    // 4. MATH1853 - Linear Algebra
    let math1853 = Course(
        courseId: "MATH1853",
        courseName: "Linear Algebra",
        professor: "Prof. Chen",
        courseCode: "MATH1853",
        credits: 3,
        courseDescription: "Introduction to linear algebra including vectors, matrices, linear transformations, and eigenvalues."
    )
    
    math1853.addClassTime(
        dayOfWeek: 2, // Tuesday
        startTime: createTime(hour: 14, minute: 0),
        endTime: createTime(hour: 15, minute: 30),
        location: "Mathematics Building Room 101"
    )
    math1853.addClassTime(
        dayOfWeek: 5, // Friday
        startTime: createTime(hour: 9, minute: 0),
        endTime: createTime(hour: 10, minute: 30),
        location: "Mathematics Building Room 101"
    )
    
    math1853.addHomework(
        homeworkId: "MATH1853_PS1",
        title: "Problem Set",
        dueDate: createDate(month: 11, day: 8, hour: 23, minute: 59)
    )
    
    courses.append(math1853)
    
    // 5. ELEC3848 - Integrated Design Project
    let elec3848 = Course(
        courseId: "ELEC3848",
        courseName: "Integrated Design Project",
        professor: "Prof. Liu",
        courseCode: "ELEC3848",
        credits: 4,
        courseDescription: "Capstone design project integrating knowledge from multiple electrical engineering courses."
    )
    
    elec3848.addClassTime(
        dayOfWeek: 3, // Wednesday
        startTime: createTime(hour: 9, minute: 0),
        endTime: createTime(hour: 12, minute: 0),
        location: "Engineering Building Lab 401"
    )
    
    elec3848.addHomework(
        homeworkId: "ELEC3848_HW",
        title: "Homework",
        dueDate: createDate(month: 12, day: 3, hour: 23, minute: 59)
    )
    
    courses.append(elec3848)
    
    // 6. COMP3297 - Software Engineering
    let comp3297 = Course(
        courseId: "COMP3297",
        courseName: "Software Engineering",
        professor: "Prof. Zhao",
        courseCode: "COMP3297",
        credits: 3,
        courseDescription: "Principles and practices of software engineering including requirements analysis, design, implementation, testing, and maintenance."
    )
    
    comp3297.addClassTime(
        dayOfWeek: 2, // Tuesday
        startTime: createTime(hour: 15, minute: 0),
        endTime: createTime(hour: 16, minute: 30),
        location: "Computer Science Building Room 210"
    )
    comp3297.addClassTime(
        dayOfWeek: 4, // Thursday
        startTime: createTime(hour: 15, minute: 0),
        endTime: createTime(hour: 16, minute: 30),
        location: "Computer Science Building Room 210"
    )
    
    comp3297.addHomework(
        homeworkId: "COMP3297_HW",
        title: "Homework",
        dueDate: createDate(month: 10, day: 20, hour: 23, minute: 59)
    )
    
    courses.append(comp3297)
    
    // 7. ELEC2347 - Fundamentals of Optics
    let elec2347 = Course(
        courseId: "ELEC2347",
        courseName: "Fundamentals of Optics",
        professor: "Prof. Yang",
        courseCode: "ELEC2347",
        credits: 3,
        courseDescription: "Introduction to the principles of optics including geometric optics, wave optics, and optical systems."
    )
    
    elec2347.addClassTime(
        dayOfWeek: 1, // Monday
        startTime: createTime(hour: 11, minute: 0),
        endTime: createTime(hour: 12, minute: 30),
        location: "Physics Building Room 105"
    )
    elec2347.addClassTime(
        dayOfWeek: 3, // Wednesday
        startTime: createTime(hour: 11, minute: 0),
        endTime: createTime(hour: 12, minute: 30),
        location: "Physics Building Room 105"
    )
    
    elec2347.addHomework(
        homeworkId: "ELEC2347_HW",
        title: "Homework",
        dueDate: createDate(month: 9, day: 15, hour: 23, minute: 59)
    )
    
    courses.append(elec2347)
    
    // 8. PHYS1240 - Physics by Inquiry
    let phys1240 = Course(
        courseId: "PHYS1240",
        courseName: "Physics by Inquiry",
        professor: "Prof. Wu",
        courseCode: "PHYS1240",
        credits: 3,
        courseDescription: "Inquiry-based approach to learning physics concepts through hands-on experiments and investigations."
    )
    
    phys1240.addClassTime(
        dayOfWeek: 4, // Thursday
        startTime: createTime(hour: 8, minute: 30),
        endTime: createTime(hour: 10, minute: 0),
        location: "Science Center Lab 203"
    )
    phys1240.addClassTime(
        dayOfWeek: 5, // Friday
        startTime: createTime(hour: 14, minute: 0),
        endTime: createTime(hour: 15, minute: 30),
        location: "Science Center Lab 203"
    )
    
    phys1240.addHomework(
        homeworkId: "PHYS1240_HW",
        title: "Homework",
        dueDate: createDate(month: 11, day: 10, hour: 23, minute: 59)
    )
    
    courses.append(phys1240)
    
    return courses
}

// 辅助函数：创建时间（只关心小时和分钟）
func createTime(hour: Int, minute: Int) -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components) ?? Date()
}

// 辅助函数：创建完整日期
func createDate(month: Int, day: Int, hour: Int, minute: Int) -> Date {
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = 2025 // 使用当前年份
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components) ?? Date()
}
