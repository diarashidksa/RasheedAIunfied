// Scripts for dashboard
document.addEventListener('DOMContentLoaded', () => {
    const totalConversationsEl = document.getElementById('total-conversations');
    const totalResponsesEl = document.getElementById('total-responses');
    const responsesPerConversationEl = document.getElementById('responses-per-conversation');
    const conversationFilterEl = document.getElementById('conversation-filter');
    const startDateEl = document.getElementById('start-date');
    const endDateEl = document.getElementById('end-date');
    const applyFiltersBtn = document.getElementById('apply-filters-btn');
    const chatTableBodyEl = document.querySelector('#chat-table tbody');
    const refreshBtn = document.getElementById('refresh-btn');
    const exportBtn = document.getElementById('export-btn');
    const tableContainer = document.getElementById('table-view');
    const langBtn = document.getElementById('lang-toggle');
    const prevPageBtn = document.getElementById('prev-page-btn');
    const nextPageBtn = document.getElementById('next-page-btn');
    const pageInfoEl = document.getElementById('page-info');

    let allChatLogs = [];
    let responsesCount = {};
    let filteredLogs = [];
    let currentPage = 1;
    const rowsPerPage = 25;

    const translations = {
        en: {
            total_conversations: 'Total Conversations',
            total_responses: 'Total Responses',
            responses_per_conversation: 'Responses per Conversation',
            select_conversation: 'Select a conversation',
            conversation_logs: 'Conversation Logs',
            filter_by_id: 'Filter by Session ID:',
            from: 'From:',
            to: 'To:',
            all_conversations: 'All Conversations',
            apply_filters: 'Apply Filters',
            refresh_data: 'Refresh Data',
            export_excel: 'Export to Excel',
            footer_text: 'Powered by',
            prev: 'Previous',
            next: 'Next',
            table_headers: ['Session ID', 'Date', 'Time', 'IP Address', 'User Message', 'Bot Response']
        },
        ar: {
            total_conversations: 'إجمالي المحادثات',
            total_responses: 'إجمالي الردود',
            responses_per_conversation: 'الردود لكل محادثة',
            select_conversation: 'اختر محادثة',
            conversation_logs: 'سجل المحادثات',
            filter_by_id: 'تصفية حسب معرف الجلسة:',
            from: 'من:',
            to: 'إلى:',
            all_conversations: 'جميع المحادثات',
            apply_filters: 'تطبيق الفلتر',
            refresh_data: 'تحديث البيانات',
            export_excel: 'تصدير إلى إكسل',
            footer_text: 'مدعوم بواسطة',
            prev: 'السابق',
            next: 'التالي',
            table_headers: ['معرف الجلسة', 'التاريخ', 'الوقت', 'عنوان IP', 'رسالة المستخدم', 'رد البوت']
        }
    };

    let currentLang = 'en';

    const setLanguage = (lang) => {
        const t = translations[lang];
        document.querySelector('.metric-card:nth-child(1) h3').textContent = t.total_conversations;
        document.querySelector('.metric-card:nth-child(2) h3').textContent = t.total_responses;
        document.querySelector('.metric-card:nth-child(3) h3').textContent = t.responses_per_conversation;
        document.querySelector('.logs-container h2').textContent = t.conversation_logs;
        document.querySelector('label[for="conversation-filter"]').textContent = t.filter_by_id;
        document.querySelector('label[for="start-date"]').textContent = t.from;
        document.querySelector('label[for="end-date"]').textContent = t.to;
        document.getElementById('apply-filters-btn').textContent = t.apply_filters;
        document.getElementById('refresh-btn').textContent = t.refresh_data;
        document.getElementById('export-btn').textContent = t.export_excel;
        document.querySelector('footer p').innerHTML = `${t.footer_text} <a href="http://www.rasheed.ai" target="_blank">www.rasheed.ai</a>`;
        langBtn.textContent = lang === 'en' ? 'عربي' : 'English';
        document.querySelector('#conversation-filter option[value=""]').textContent = t.all_conversations;
        prevPageBtn.textContent = t.prev;
        nextPageBtn.textContent = t.next;

        const tableHeaders = document.querySelectorAll('#chat-table th');
        t.table_headers.forEach((header, index) => {
            if (tableHeaders[index]) {
                tableHeaders[index].textContent = header;
            }
        });

        document.body.dir = lang === 'ar' ? 'rtl' : 'ltr';
    };

    const renderDashboard = (data) => {
        if (!data) {
            console.error("No data received.");
            return;
        }
        allChatLogs = data.chat_logs;
        responsesCount = data.responses_per_conversation;

        totalConversationsEl.textContent = data.num_conversations;
        totalResponsesEl.textContent = allChatLogs.length;

        conversationFilterEl.innerHTML = `<option value="">${translations[currentLang].all_conversations}</option>`;
        const sessionIds = [...new Set(allChatLogs.map(log => log['Session ID']))].sort();
        sessionIds.forEach(id => {
            const option = document.createElement('option');
            option.value = id;
            option.textContent = id;
            conversationFilterEl.appendChild(option);
        });

        // The table is not shown until filters are applied
        tableContainer.style.display = 'none';
        filteredLogs = [];
        updatePaginationButtons();
        renderTable([]);
    };

    const renderTable = (logs) => {
        chatTableBodyEl.innerHTML = '';
        if (logs.length === 0) {
            chatTableBodyEl.innerHTML = '<tr><td colspan="6">No conversations found.</td></tr>';
            return;
        }

        const start = (currentPage - 1) * rowsPerPage;
        const end = start + rowsPerPage;
        const pageLogs = logs.slice(start, end);

        pageLogs.forEach(log => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${log['Session ID']}</td>
                <td>${log['Date']}</td>
                <td>${log['Time']}</td>
                <td>${log['IP Address']}</td>
                <td>${log['User Message']}</td>
                <td>${log['Bot Response']}</td>
            `;
            chatTableBodyEl.appendChild(row);
        });
    };

    const updatePaginationButtons = () => {
        const totalPages = Math.ceil(filteredLogs.length / rowsPerPage);
        prevPageBtn.disabled = currentPage === 1;
        nextPageBtn.disabled = currentPage === totalPages || filteredLogs.length <= rowsPerPage;
        pageInfoEl.textContent = `Page ${totalPages > 0 ? currentPage : 0} of ${totalPages}`;
    };

    const applyFilters = () => {
        let logs = allChatLogs;
        const selectedSessionId = conversationFilterEl.value;
        const startDate = startDateEl.value;
        const endDate = endDateEl.value;

        if (selectedSessionId) {
            logs = logs.filter(log => log['Session ID'] === selectedSessionId);
            responsesPerConversationEl.textContent = responsesCount[selectedSessionId] || 0;
        } else {
            responsesPerConversationEl.textContent = translations[currentLang].select_conversation;
        }

        if (startDate) {
            const start = new Date(startDate);
            logs = logs.filter(log => new Date(log['Date']) >= start);
        }

        if (endDate) {
            const end = new Date(endDate);
            logs = logs.filter(log => new Date(log['Date']) <= end);
        }

        filteredLogs = logs;
        currentPage = 1;
        renderTable(filteredLogs);
        updatePaginationButtons();
        tableContainer.style.display = 'block';
    };

    // Manual Refresh Button Event Listener
    refreshBtn.addEventListener('click', () => {
        refreshBtn.textContent = "Refreshing...";
        fetch('/refresh_data')
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    renderDashboard(data.data);
                    conversationFilterEl.value = '';
                    startDateEl.value = '';
                    endDateEl.value = '';
                    totalConversationsEl.textContent = data.data.num_conversations;
                    totalResponsesEl.textContent = data.data.chat_logs.length;
                    responsesPerConversationEl.textContent = translations[currentLang].select_conversation;
                    tableContainer.style.display = 'none';
                } else {
                    console.error("Failed to refresh data:", data.message);
                    alert("Failed to refresh data. Check the server logs.");
                }
                refreshBtn.textContent = translations[currentLang].refresh_data;
            })
            .catch(error => {
                console.error("Error fetching refresh data:", error);
                alert("An error occurred. Check the console for details.");
                refreshBtn.textContent = translations[currentLang].refresh_data;
            });
    });

    // Auto-refresh function
    // ... (previous code remains the same)

// New function to update only the dashboard metrics
const updateMetrics = (data) => {
    if (!data) return;
    totalConversationsEl.textContent = data.num_conversations;
    totalResponsesEl.textContent = data.chat_logs.length;

    // Only update the responses per conversation if a session is currently selected
    const selectedSessionId = conversationFilterEl.value;
    if (selectedSessionId) {
        responsesPerConversationEl.textContent = data.responses_per_conversation[selectedSessionId] || 0;
    }
};

// Auto-refresh function that calls the new updateMetrics function
const autoRefreshDashboard = () => {
    fetch('/refresh_data')
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Update the global data variables
                allChatLogs = data.data.chat_logs;
                responsesCount = data.data.responses_per_conversation;

                // Update metrics without affecting the table or filters
                updateMetrics(data.data);
                console.log("Dashboard metrics automatically refreshed.");
            } else {
                console.error("Failed to auto-refresh data:", data.message);
            }
        })
        .catch(error => {
            console.error("Error during auto-refresh:", error);
        });
};

// ... (rest of the script remains the same)

    // Set auto-refresh to every 2 seconds (2000ms)
    setInterval(autoRefreshDashboard, 2000);

    exportBtn.addEventListener('click', () => {
        window.location.href = '/export_excel';
    });

    langBtn.addEventListener('click', () => {
        currentLang = currentLang === 'en' ? 'ar' : 'en';
        setLanguage(currentLang);
        renderDashboard({
            num_conversations: new Set(allChatLogs.map(l => l['Session ID'])).size,
            responses_per_conversation: responsesCount,
            chat_logs: allChatLogs
        });
    });

    applyFiltersBtn.addEventListener('click', applyFilters);

    prevPageBtn.addEventListener('click', () => {
        if (currentPage > 1) {
            currentPage--;
            renderTable(filteredLogs);
            updatePaginationButtons();
        }
    });

    nextPageBtn.addEventListener('click', () => {
        const totalPages = Math.ceil(filteredLogs.length / rowsPerPage);
        if (currentPage < totalPages) {
            currentPage++;
            renderTable(filteredLogs);
            updatePaginationButtons();
        }
    });

    // Initial data load on page load
    fetch('/refresh_data')
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                renderDashboard(data.data);
            } else {
                console.error("Failed to load initial data:", data.message);
                alert("Failed to load initial data. Check the server logs.");
            }
        });

    setLanguage(currentLang);
});