from rest_framework.pagination import PageNumberPagination

import json
class CustomPagination(PageNumberPagination):
    page_size = 20
    page_query_param = 'page_size'
    max_page_size = 100

def Multiplechoiceresultvalidator(response, solution, section):
    positive_mark = 0
    negetive_mark = 0
    response= {int(key): value for key, value in response.items()}
    for question_id in solution:
        if question_id in response:
            if response[question_id] == solution[question_id]:
                positive_mark+=section.positive_marks
            elif response[question_id] == "":
                pass
            else:
                negetive_mark+=section.negetive_mark
    #mark = max(mark, 0)
    return positive_mark, negetive_mark


def MultipleChoiceSolutionCreator(questions):
    answers = {}
    for question in questions:
        question_id = question.mcq_id
        answer = question.answer
        answers[question_id] = answer
    return answers


def MultiSelectresultvalidator(response, solution, section):
    positive_mark = 0
    negetive_mark = 0
    response= {int(key): value for key, value in response.items()}

    for question_id in solution:
        if question_id in response:
            if set(response[question_id]) == set(solution[question_id]):
                    positive_mark +=section.positive_marks
            else:
                pass
    #mark = max(mark, 0)
    return positive_mark


def MultiseleceSolutionCreator(questions):
    from exam.models import Options
    answers = {}
    crct_option_stack = []
    
    for question in questions:
        question_id = question.msq_id
        options = Options.objects.filter( question = question)
        for option in options:
            if option.is_answer == True:
                crct_option_stack.append(str(option.option_id))
        answers[question_id] = crct_option_stack
        crct_option_stack = []
    return answers


def Numericalresultvalidator(response, section):
    from exam.models import Numericals
    positive_mark = 0
    negetive_mark = 0

    for question_id in response:
        question = Numericals.objects.get(nq_id = question_id)
        min_range = question.ans_min_range
        max_range = question.ans_max_range
        if min_range < response[question_id] < max_range:
            positive_mark += section.positive_marks
        elif response[question_id] == "":
                pass
        else:
            negetive_mark += section.negetive_mark

    return positive_mark, negetive_mark


def SectionBasedEvaluator(section_data):
    """In this class, questions are evaluated section wise. categorised response (mulitplechoice, multiselect, numerical) are seperated and 
    evaluated. no of correct answers and wrong answers made are calculated basesd on evaluated score. Then three conditions are checked.
    1. if no of questions attended equal to no of questions to be evaluated.
    2. if no of questions attended less than no of questions to be evaluated. in this three other cases are checked with the remaining no of questions to be evaluated
    3. if no of questions attended greater than no of questions to be evaluated"""

    from exam.models import Sections
    #takes multiplechoice, multiselect, numerical keys dictionary from section_data passed to this function.
    multiple_choice_response = section_data['multiplechoice']
    numericals_response = section_data['numericals']
    multiselect_response = section_data['multiselect']
    # numericals_response = section_data['numericals']

    #get the section from database with section_id for create solution for section.
    section_id = section_data['id']
    section = Sections.objects.get(id=section_id)


    section_score = section.total_score
    positive_score = section.positive_marks
    negetive_score = section.negetive_mark
    lookup_questions = section.no_of_ques_to_be_validated
    multiple_choice_queses = section.multiplechoice.all()
    multiple_choice_score_positive = 0
    multiple_choice_score_negetive = 0
    if multiple_choice_queses:
        solutions = MultipleChoiceSolutionCreator(questions=multiple_choice_queses)
        multiple_choice_score_positive, multiple_choice_score_negetive = Multiplechoiceresultvalidator(response=multiple_choice_response, solution=solutions, section=section)

    multiselect_queses = section.multiselect.all()
    multiselect_score_positive = 0

    if multiselect_queses:
        solutions = MultiseleceSolutionCreator(questions=multiselect_queses)
        multiselect_score_positive = MultiSelectresultvalidator(response=multiselect_response, solution=solutions, section=section)

    numericals_queses = section.numericals.all()
    numerical_score_positive = 0
    numerical_score_negetive = 0

    if numericals_queses:
        numerical_score_positive, numerical_score_negetive = Numericalresultvalidator(response=numericals_response, section=section)

    total_positive_score = multiple_choice_score_positive + multiselect_score_positive + numerical_score_positive
    total_negetive_score = multiple_choice_score_negetive + numerical_score_negetive
    attended_questions_correct = total_positive_score / positive_score
    print(f"negetive_score{negetive_score}")
    if negetive_score:
        attended_questions_wrong = total_negetive_score / negetive_score

    if attended_questions_correct == lookup_questions:
        return total_positive_score
    
    elif attended_questions_correct < lookup_questions:
        remaining = lookup_questions - attended_questions_correct

        if negetive_score:
            if remaining <= attended_questions_wrong:
                total_positive_score -= remaining * negetive_score

            elif remaining > attended_questions_wrong:
                total_positive_score -= attended_questions_wrong * negetive_score
        else:
            pass
    else:
        total_positive_score = lookup_questions * positive_score

    return total_positive_score


def ExamScoreEvaluator(response):
    # response = json.loads(response)
    if isinstance(response, str):
        response = json.loads(response)
    # Ensure response keys are integers and iterate over section data
    response = {int(key): value for key, value in response.items()}
    score = 0
    # Iterate for each section in response
    for section_id, section_data in response.items():
        section_data['id'] = section_id  # Add the section ID to the section data
        score += SectionBasedEvaluator(section_data=section_data)
    return score

# response = {
#     '3':{'multiplechoice':{'1':"A",
#                            '2':"B",
#                            '3':"C",
#                            '4':"D"},
#         'multiselect':{'1':[1,2,4],
#                         '2':[1,2]}, 
#         'numericals':{},
#         },
# }
    
# # print(ExamScoreEvaluator(response=response))

# response = {
#     'section_id_1':{'multiplechoice':{'question_id_1':"solution option letter 1",
#                                       'question_id_2':"solution option letter 2",
#                                       'question_id_3':"solution option letter 3",},
#                   'multiselect':{'question_id_1':[1,2,3],
#                                  'question_id_2':[1,2,3],
#                                  'question_id_3':[1,2,3],}, # 1,2,3 are the id of correct options
#                   'numericals':{'question_id_1': 1.2,
#                                 'question_id_2': 2.3,
#                                 'question_id_3': 5.2},
#                   },

#     'section_id_2':{'multiplechoice':{'question_id':"solution option letter"},
#                   'multiselect':{'question_id':[1,2,3]}, # 1,2,3 are the id of correct options
#                   'numericals':{'question_id': 1.2},
#                   }
# }



# {
#     "3":{"multiplechoice":{"1":"A",
#                            "2":"B",
#                            "3":"C",
#                            "4":"D"},
#          "multiselect":{"1":["1","2","4"],
#                         "2":["6","7"]},
#          "numericals":{}
#          },
#     "4":{"multiplechoice":{},
#          "multiselect":{},
#          "numericals":{}}
# }



# {
#     "3":{"multiplechoice":{"1":"A",
#                            "2":"B",
#                            "3":"C",
#                            "4":"D"},
#         "multiselect":{"1":[1,2,4],
#                         "2":[1,2]}, 
#         "numericals":{}
#         }
# }

{"exam_id":1,
 "time_taken":"0:10:00",
 "exam_response":{
     "3":{"multiplechoice":{"1":"B","2":"C","3":"D","4":"A"},
          "multiselect":{"1":["1","2","4"],"2":["6","7"]},
          "numericals":{"1":1.60,
                        "2":4.0}},
    "4":{"multiplechoice":{},
         "multiselect":{},
         "numericals":{}}
         }
}
